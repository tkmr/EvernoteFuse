#!/usr/bin/env ruby
require 'fusefs'
require File.join(File.dirname(__FILE__), 'cache_fs.rb')
require File.join(File.dirname(__FILE__), '..', 'evernote.rb')

module EvernoteFS
  class Root < CachedDir
    attr_accessor :core

    def initialize(conf)
      super()
      @core = REvernote::init conf
      @core.notebooks.each do |nb|
        self.mkdir(nb.name, Notebook.new(nb))
      end
    end
  end

  class Notebook < CachedDir
    attr_accessor :book

    def initialize(notebook)
      super()
      @book = notebook
      @book.find_notes.each do |note|
        self.mkdir(note.title, Note.new(note))
      end
    end
  end

  class Note < CachedDir
    attr_accessor :note
    def initialize(my_note)
      super()
      @note = my_note
      @content = NoteContent.new(to_uniq('content'), @note)
      self.write_to('title', @note.title)
      self.write_to('content', @content)
      self.write_to('guid', @note.guid)
    end

    def to_uniq(name)
      "evernote::#{uniqid}::#{name}"
    end

    def uniqid
      @note.guid
    end
  end

  class NoteContent < CachedFile
    include CachedFile::CallbackBase
    def initialize(id, note)
      @note = note
      super(id, self)
    end

    def read
      @note.load_content
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
