#!/usr/bin/env ruby
require 'fusefs'
require File.join(File.dirname(__FILE__), 'cache_fs.rb')
require File.join(File.dirname(__FILE__), '..', 'evernote.rb')

module EvernoteFS
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
  end

  class Notebook < CachedDir
    include CachedDir::CallbackBase
    attr_accessor :book

    def initialize(notebook)
      super(self)
      @book = notebook
      load_notes
    end

    def load_notes(offset = 0)
      res = @book.find_notes_with_option(offset)
      res[:notes].each_with_index do |note, idx|
        format = "%0#{res[:total_notes].to_s.length}d"
        id = sprintf(format, (res[:total_notes] - (offset + idx)))
        note_fs = Note.new(note, id)
        self.write_to(note_fs.file_name, note_fs)
      end
    end

    def new_file(name, content = nil)
      content ||= ""
      Note.new(@book.create_note(:title => name, :content => content))
    end
  end

  class Note < CachedFile
    include CachedFile::CallbackBase
    attr_accessor :note

    def initialize(my_note, id = nil)
      @note = my_note
      @id   = id
      super(@note.to_uniq_key('note_content'), self)
    end

    def act_read
      REvernote::Logger.info ['EvernoteFS::Note#read was called', self]
      @note.load_content
    end

    def act_write(body)
      REvernote::Logger.info ['EvernoteFS::Note#write was called', self, body]
      @note.content = body
      @note.save
      @note.content
    end

    def updated_at
      REvernote::Logger.info ['EvernoteFS::Note#updated_at', @note.updated_at]
      @note.updated_at
    end

    def file_name
      @id ? "#{@id}_#{@note.title}" : @note.title
    end
  end
end

if __FILE__ == $0
  target_path = ARGV.shift
  raise 'Argument error! set a mount point' unless target_path
  REvernote::Logger.init(REvernote::DEV_CONF.logger)
  root = EvernoteFS::Root.new(REvernote::DEV_CONF)
  FuseFS.set_root(root)
  FuseFS.mount_under(target_path)
  FuseFS.run
end
