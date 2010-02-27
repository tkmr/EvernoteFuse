module EvernoteFS
  class Note < CachedFile
    include CachedFile::CallbackBase
    attr_accessor :note, :notebook

    def initialize(my_note, id = nil, notebook = nil)
      @notebook = notebook
      @note = my_note
      @id   = id
      super(@note.to_uniq_key('note_content'), self)
    end

    def act_read
      @note.load_content
    end

    def act_write(body)
      @note.content = body
      @note.save
      @note.content
    end

    def updated_at
      REvernote::Logger.info ["EvernoteFS::Note#updated_at - #{@note.updated_at}"]
      @note.updated_at
    end

    def file_name
      @id ? "#{@id}_#{@note.title}" : @note.title
    end

    def note_mode
      @notebook.note_mode
    end

    def cache_limit_sec
      @notebook.conf['cache_limit_sec']
    end
  end
end
