module EvernoteFS
  module ActsAsHtmlableNote
    extend ExtendModule
    def read_file(path)
      result = super
      REvernote::ENML.enml_to_html(result)
    end

    def write_to(path, file)
      file = REvernote::ENML.html_to_enml(file) if file.class == String
      super(path, file)
    end
  end
end
