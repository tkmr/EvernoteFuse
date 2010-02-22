#!/usr/bin/env ruby
require 'fusefs'
require File.join(File.dirname(__FILE__), 'cache_fs.rb')
require File.join(File.dirname(__FILE__), '..', 'evernote.rb')

module EvernoteFS
  class Conf < REvernote::Conf
    CONF_NAME = 'evernote_conf.yaml'

    class << self
      def init(yaml_file = CONF_NAME)
        conf = super(yaml_file)
        REvernote::Logger.init(conf.logger)
        conf
      end

      def notebook(notebook_name)
        unless @notebooks_conf_cache && @notebooks_conf_cache[notebook_name]
          @notebooks_conf_cache ||= {}
          @notebooks_conf_cache[notebook_name] ||= main_conf.notebooks[:default].merge(main_conf.notebooks[notebook_name] || {})
        end
        @notebooks_conf_cache[notebook_name]
      end

      def connection
        main_conf.connection
      end

      def main_conf
        @main_conf ||= init()
      end
    end
  end

  class Root < CachedDir
    include CachedDir::CallbackBase
    attr_accessor :core

    def initialize(conf)
      super(self)
      @core = REvernote::init conf
      @core.notebooks.each do |nb|
        self.mkdir(nb.name, Notebook.new(nb))
      end
    end

    def mount(target_path)
      FuseFS.set_root(self)
      FuseFS.mount_under(target_path)
    end
  end

  class Notebook < CachedDir
    include CachedDir::CallbackBase
    attr_accessor :book

    def initialize(notebook)
      super(self)
      @book = notebook
      load_notes
      enable_special_mode
    end

    def enable_special_mode
      if note_mode
        case note_mode
        when 'readonly'
          ActsAsReadOnly.apply_to self
        when 'html'
          ActsAsHtmlableNote.apply_to self
        when 'text'
          ActsAsTextableNote.apply_to self
        end
      end
    end

    def load_notes(offset = 0)
      res = @book.find_notes_with_option(offset)
      res[:notes].each_with_index do |note, idx|
        format = "%0#{res[:total_notes].to_s.length}d"
        id = sprintf(format, (res[:total_notes] - (offset + idx)))
        note_fs = Note.new(note, id, self)
        self.write_to(note_fs.file_name, note_fs)
      end
    end

    def new_file(name, content = nil)
      content ||= ""
      Note.new(@book.create_note(:title => name, :content => content), nil, self)
    end

    def refresh_interval_sec
      conf['refresh_interval_sec']
    end

    def note_mode
      conf['note_mode']
    end

    def conf
      EvernoteFS::Conf.notebook(@book.name)
    end
  end

  class Note < CachedFile
    include CachedFile::CallbackBase
    attr_accessor :note, :notebook

    def initialize(my_note, id = nil, notebook = nil)
      @notebook = notebook
      @note = my_note
      @id   = id
      super(@note.to_uniq_key('note_content'), self)
    end

    def act_read
      @note.load_content
    end

    def act_write(body)
      @note.content = body
      @note.save
      @note.content
    end

    def updated_at
      REvernote::Logger.info ["EvernoteFS::Note#updated_at - #{@note.updated_at}"]
      @note.updated_at
    end

    def file_name
      @id ? "#{@id}_#{@note.title}" : @note.title
    end

    def note_mode
      @notebook.note_mode
    end

    def cache_limit_sec
      @notebook.conf['cache_limit_sec']
    end
  end

  module ActsAsHtmlableNote
    extend ExtendModule
    def read_file(path)
      result = super
      REvernote::ENML.enml_to_html(result)
    end

    def write_to(path, file)
      file = REvernote::ENML.html_to_enml(file) if file.class == String
      super(path, file)
    end
  end

  module ActsAsTextableNote
    extend ExtendModule
    def read_file(path)
      result = super
      REvernote::ENML.enml_to_text(result)
    end

    def write_to(path, file)
      file = REvernote::ENML.text_to_enml(file) if file.class == String
      super(path, file)
    end
  end
end

if __FILE__ == $0
  target_path = ARGV.shift
  raise 'Argument error! set a mount point' unless target_path

  # mount
  root = EvernoteFS::Root.new(EvernoteFS::Conf.connection)
  root.mount(target_path)

  # trap exit()
  END {
    system("sudo umount #{target_path}")
  }
  FuseFS.run
end
