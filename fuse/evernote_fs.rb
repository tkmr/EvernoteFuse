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
      @book.find_notes.each do |note|
        self.write_to(note.title, Note.new(note))
      end
    end

    def new_file(name, content = nil)
      content ||= ""
      @book.create_note(:title => name, :content => content)
    end
  end

  class Note < CachedFile
    include CachedFile::CallbackBase
    attr_accessor :note

    def initialize(my_note)
      @note = my_note
      super(@note.to_uniq_key('note_content'), self)
    end

    def read
      @note.load_content
    end

    def updated_at
      @note.updated_at
    end
  end
end

if __FILE__ == $0
  target_path = ARGV.shift
  raise 'Argument error! set a mount point' unless target_path
  root = EvernoteFS::Root.new(REvernote::DEV_CONF)
  FuseFS.set_root(root)
  FuseFS.mount_under(target_path)
  FuseFS.run
end
