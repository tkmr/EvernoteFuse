require "rubygems"
require "delegate"
require "digest/md5"
require 'evernote_libs.rb'
require 'evernote_enml.rb'

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
    FIELDS = Evernote::EDAM::Type::Note::FIELDS
    attr_accessor :note

    def initialize(note, core)
      @note = note
      @core = core
      super(@note)
    end

    def load_content
      self.content = @core.note_store.getNoteContent(@core.auth_token, self.guid)
    end

    def to_uniq_key(name)
      "evernote::#{self.guid}::#{name}"
    end

    alias_method :old_content_setter, :content=
    def content=(value)
      unless REvernote::ENML.is_enml?(value)
        value = REvernote::ENML.new(value).to_s
      end
      self.old_content_setter value
    end

    def save
      @core.note_store.updateNote(@core.auth_token, @note)
    end

    def updated_at
      Time.at(updated / 1000)
    end

    class << self
      def build(core, options)
        if options[:content].class == REvernote::ENML
          options[:content] = options[:content].to_s
        else
          options[:content] = REvernote::ENML.new(options[:content]).to_s
        end
        raw_note = Evernote::EDAM::Type::Note.new(options)
        self.new(raw_note, core)
      end
    end
  end

  # guid
  # name
  class Notebook < DelegateClass(Evernote::EDAM::Type::Notebook)
    FIELDS = Evernote::EDAM::Type::Notebook::FIELDS
    attr_accessor :notes

    def initialize(notebook, core)
      @notebook = notebook
      @core = core
      @notes = {}
      super(@notebook)
    end

    def find_notes(offset = 0, max = 100)
      filter = Evernote::EDAM::NoteStore::NoteFilter.new
      filter.notebookGuid = self.guid
      filter.ascending = false
      list = @core.note_store.findNotes(@core.auth_token, filter, offset, max)
      list.notes.map do |raw_note|
        note =  Note.new(raw_note, @core)
        push_note note
        note
      end
    end

    def get_note(guid)
      raw_note = @core.note_store.getNote(@core.auth_token, guid, true, false, false, false)
      note = Note.new(raw_note, @core)
      push_note note
    end

    def create_note(note_base)
      note_base = Note.build(@core, note_base) if note_base.is_a?(Hash)
      raw_note = note_base.instance_of?(REvernote::Note) ? note_base.note : note_base
      new_note = @core.note_store.createNote(@core.auth_token, raw_note)
      note = Note.new(new_note, @core)
      push_note note
    end

    private
    def push_note(note)
      @notes[note.guid] = note
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
