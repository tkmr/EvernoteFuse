require 'yaml'
require "rubygems"
require "delegate"
require "digest/md5"
require File.join(File.dirname(__FILE__), 'evernote_libs.rb')
require File.join(File.dirname(__FILE__), 'evernote_conf.rb')
require File.join(File.dirname(__FILE__), 'evernote_logger.rb')
require File.join(File.dirname(__FILE__), 'evernote_enml.rb')
require File.join(File.dirname(__FILE__), 'evernote_note.rb')
require File.join(File.dirname(__FILE__), 'evernote_notebook.rb')

module REvernote
  class ArgumentInvalidException < Exception; end
  def self.init(conf)
    Core.new(conf)
  end

  class Core
    attr_accessor :note_store, :notebooks, :auth_token

    def initialize(conf)
      self.login(conf)
      @note_store = Evernote::EDAM::NoteStore::NoteStore::Client.new(self.getProtocol(conf.noteStoreUrlBase + @user.shardId))
      @notebooks = @note_store.listNotebooks(@auth_token).map do |l|
        book = Notebook.new(l, self)
        @defaultNotebook = book if book.defaultNotebook
        book
      end
    end

    def default_notebook
      @defaultNotebook
    end

    def login(conf)
      REvernote::Logger.info ['Core#login was called']

      userStore = Evernote::EDAM::UserStore::UserStore::Client.new(self.getProtocol(conf.userStoreUrl))
      unless userStore.checkVersion("Ruby EDAMTest", Evernote::EDAM::UserStore::EDAM_VERSION_MAJOR, Evernote::EDAM::UserStore::EDAM_VERSION_MINOR)
        raise "Evernote client version is invalid"
      end
      authResult = userStore.authenticate(conf.username, conf.password, conf.consumerKey, conf.consumerSecret)
      @user = authResult.user
      @auth_token = authResult.authenticationToken
    end

    def getProtocol(url)
      transport = Thrift::HTTPClientTransport.new(url)
      return Thrift::BinaryProtocol.new(transport)
    end
  end
end
