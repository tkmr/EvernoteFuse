module REvernote
  class Note < DelegateClass(Evernote::EDAM::Type::Note)
    FIELDS = Evernote::EDAM::Type::Note::FIELDS
    attr_accessor :note

    def initialize(note, core)
      @note = note
      @core = core
      super(@note)
    end

    def load_content
      REvernote::Logger.info ["Note#load_content was called - #{@note.title} -  #{@note.guid}"]
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
      REvernote::Logger.info ["Note#save was called - #{@note.title} - #{@note.guid}"]
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
end
