module EvernoteFS
  class Notebook < CachedDir
    include CachedDir::CallbackBase
    attr_accessor :book

    def initialize(notebook)
      super(self)
      @book = notebook
      load_notes
      enable_special_mode
    end

    def enable_special_mode
      if note_mode
        case note_mode
        when 'readonly'
          ActsAsReadOnly.apply_to self
        when 'html'
          ActsAsHtmlableNote.apply_to self
        when 'text'
          ActsAsTextableNote.apply_to self
        end
      end
    end

    def load_notes(offset = 0)
      res = @book.find_notes_with_option(offset)
      res[:notes].each_with_index do |note, idx|
        format = "%0#{res[:total_notes].to_s.length}d"
        id = sprintf(format, (res[:total_notes] - (offset + idx)))
        note_fs = Note.new(note, id, self)
        self.write_to(note_fs.file_name, note_fs)
      end
    end

    def new_file(name, content = nil)
      content ||= ""
      Note.new(@book.create_note(:title => name, :content => content), nil, self)
    end

    def refresh_interval_sec
      conf['refresh_interval_sec']
    end

    def note_mode
      conf['note_mode']
    end

    def conf
      EvernoteFS::Conf.notebook(@book.name)
    end
  end
end
