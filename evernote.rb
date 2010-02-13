require "rubygems"
require "delegate"
require "digest/md5"
require 'evernote_libs.rb'
require 'evernote_enml.rb'

module REvernote
  class ArgumentInvalidException < Exception; end

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
      REvernote::Logger.info ['Note#load_content was called', self]
      self.content = @core.note_store.getNoteContent(@core.auth_token, self.guid)
    end

    def to_uniq_key(name)
      "evernote::#{self.guid}::#{name}"
    end

    alias_method :old_content_setter, :content=
    def content=(value)
      self.old_content_setter(REvernote::ENML.new(value).to_s)
    end

    def save
      REvernote::Logger.info ['Note#save was called', self]
      @core.note_store.updateNote(@core.auth_token, @note)
    end

    def updated_at
      Time.at(updated / 1000)
    end

    class << self
      def build(core, options)
        options[:content] = REvernote::ENML.new(options[:content]).to_s
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
      REvernote::Logger.info ['Notebook#find_notes was called', self]

      filter = new_filter(:guid => self.guid, :asc => false)
      @core.note_store.findNotes(@core.auth_token, filter, offset, max).notes.map do |raw_note|
        convert_and_push_note raw_note
      end
    end

    def get_note(guid)
      REvernote::Logger.info ['Notebook#get_note was called', self]
      convert_and_push_note @core.note_store.getNote(@core.auth_token, guid, true, false, false, false)
    end

    def create_note(note_base)
      REvernote::Logger.info ['Notebook#create_note was called', self]

      case note_base.class.name
      when "Hash"
        raw_note = Note.build(@core, note_base).note
      when "REvernote::Note"
        raw_note = note_base.note
      when "Evernote::EDAM::Type::Note"
        raw_note = note_base
      else
        raise ArgumentInvalidException.new
      end
      convert_and_push_note @core.note_store.createNote(@core.auth_token, raw_note)
    end

    def new_filter(options = {})
      filter = Evernote::EDAM::NoteStore::NoteFilter.new
      filter.notebookGuid = options[:guid] if options.has_key?(:guid)
      filter.ascending    = options[:asc]  if options.has_key?(:asc)
      filter
    end

    def convert_and_push_note(raw_note)
      note = Note.new(raw_note, @core)
      @notes[note.guid] = note
      note
    end
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
      REvernote::Logger.info ['Core#login was called', self]

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


  class Logger
    class << self
      def init(conf)
        @logger = ::Logger.new(conf[:path])
        @logger.level = conf[:level] || ::Logger::WARN
      end

      def method_missing(name, *args)
        msg = args.first
        if @logger
          if msg.class == Array
            msg.each{|m|  @logger.send(name, m.inspect)  }
          else
            @logger.send(name, msg.inspect)
          end
          @logger.send(name, caller.inspect)
        end
      end
    end
  end

end

# fr test
require 'evernote_conf'
