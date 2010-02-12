require 'rexml/document'

module REvernote
  class ENML
    attr_accessor :xml
    BASEXML = <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE en-note SYSTEM "http://xml.evernote.com/pub/enml.dtd">
<en-note></en-note>
EOF

    def initialize(body)
      @xml = REXML::Document.new BASEXML
      if body.instance_of? REXML::Document
        @xml = body
      elsif body.instance_of? REXML::Element
        @xml.root.add body
      else
        elem = REXML::Element.new 'div'
        elem.add REXML::Text.new(body.to_s)
        @xml.root.add elem
      end
    end

    def to_s
      @xml.to_s
    end

    def self.is_enml?(text)
      begin
        doc = REXML::Document.new text
      rescue
        return false
      end
      doc.root.instance_of?(REXML::Element) && doc.root.name == 'en-note'
    end
  end
end
