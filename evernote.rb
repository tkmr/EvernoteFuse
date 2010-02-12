require "rubygems"
require "delegate"
require "digest/md5"
require 'evernote_libs.rb'

module REvernote
  def self.init(conf)
    Core.new(conf)
  end

  class Conf
    def initialize conf
      @conf = conf
    end

    private
    def method_missing(name, *args)
      @conf[name.to_sym]
    end
  end

  # guid
  # title
  # content
  class Note < DelegateClass(Evernote::EDAM::Type::Note)
    def initialize(note, core)
      @note = note
      @core = core
      super(@note)
    end

    def load_content
      self.content = @core.note_store.getNoteContent(@core.auth_token, self.guid)
    end
  end

  # guid
  # name
  class Notebook < DelegateClass(Evernote::EDAM::Type::Notebook)
    def initialize(notebook, core)
      @notebook = notebook
      @core = core
      super(@notebook)
    end

    def find_notes(offset = 0, max = 100)
      filter = Evernote::EDAM::NoteStore::NoteFilter.new
      filter.notebookGuid = self.guid
      filter.ascending = false
      list = @core.note_store.findNotes(@core.auth_token, filter, offset, max)
      list.notes.map do |note|
        Note.new(note, @core)
      end
    end
  end

  class Core
    attr_accessor :note_store
    attr_accessor :notebooks
    attr_accessor :auth_token

    def initialize(conf)
      self.login(conf)

      #setup notestore
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

# fr test
require 'evernote_conf'
