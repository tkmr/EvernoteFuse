module REvernote
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
      find_notes_with_option(offset, max)[:notes]
    end

    def find_notes_with_option(offset = 0, max = 100)
      REvernote::Logger.info ["Notebook#find_notes was called - #{@notebook.name} - #{@notebook.guid}"]

      filter = new_filter(:guid => self.guid, :asc => false)
      result = @core.note_store.findNotes(@core.auth_token, filter, offset, max)
      return {
        :notes => result.notes.map{|n| convert_and_push_note n },
        :total_notes => result.totalNotes
      }
    end

    def get_note(guid)
      REvernote::Logger.info ["Notebook#get_note('#{guid}') was called - #{@notebook.name} - #{@notebook.guid}"]
      convert_and_push_note @core.note_store.getNote(@core.auth_token, guid, true, false, false, false)
    end

    def create_note(note_base)
      REvernote::Logger.info ["Notebook#create_note was called - #{note_base}"]

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

      raw_note.notebookGuid = self.guid
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
end
