#!/usr/bin/env ruby
require 'fusefs'
require File.join(File.dirname(__FILE__), '..', 'evernote', 'evernote.rb')
require File.join(File.dirname(__FILE__), 'cache_fs.rb')
require File.join(File.dirname(__FILE__), 'evernote_fs_conf.rb')
require File.join(File.dirname(__FILE__), 'evernote_fs_notebook.rb')
require File.join(File.dirname(__FILE__), 'evernote_fs_note.rb')
require File.join(File.dirname(__FILE__), 'evernote_fs_html.rb')
require File.join(File.dirname(__FILE__), 'evernote_fs_text.rb')

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

    def mount(target_path)
      FuseFS.set_root(self)
      FuseFS.mount_under(target_path)
    end
  end
end
