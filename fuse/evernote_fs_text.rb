module EvernoteFS
  module ActsAsTextableNote
    extend ExtendModule
    def read_file(path)
      result = super
      REvernote::ENML.enml_to_text(result)
    end

    def write_to(path, file)
      file = REvernote::ENML.text_to_enml(file) if file.class == String
      super(path, file)
    end
  end
end
