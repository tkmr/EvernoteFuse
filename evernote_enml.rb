require 'rexml/document'
require 'enml_dtd.rb'

module REvernote
  class ENMLConvertError < Exception; end
  class ENML
    class << self
      def enml_to_html(enml)
        e = self.new(enml.to_s)
        [HTML_HEAD, '<body>', e.content.children.to_s, '</body></html>'].join("\n")
      end

      def html_to_enml(html)
        if m = html.match(/.*<body>(.*)<\/body>.*/m)
          ENML.new(m[1]).to_s
        else
          html
        end
      end
    end

    def initialize(body)
      @checked_myxml = false
      @xml = REXML::Document.new BASEXML

      case body.class.name
      when 'REvernote::ENML'
        @xml = body.xml

      when 'REXML::Document'
        @xml = body

      when 'REXML::Element'
        @xml.root.add body

      when 'String'
        if self.class.is_enml?(body)
          @xml = REXML::Document.new(body)

        elsif self.class.is_xml?(body)
          elem = REXML::Document.new body
          @xml.root.add elem.root

        else
          elem = REXML::Element.new 'div'
          elem.add REXML::Text.new(body.to_s)
          @xml.root.add elem
        end

      else
        REvernote::Logger.info ['Evernote::ENML#initialize was called', body]
        raise ENMLConvertError.new
      end
    end

    def content
      @xml.root
    end

    def xml
      @checked_myxml = false
      @xml
    end

    def xml=(value)
      @checked_myxml = false
      @xml = value
    end

    def to_s
      unless @checked_myxml
        clean_tags(@xml.root)
        @checked_myxml = true
      end
      @xml.to_s
    end

    def clean_tags(element)
      if element.class == REXML::Element
        name = element.name.upcase

        # check the white list of tagname
        unless TAGS.include?(name)
          if REPLACE_TAGS[name]
            element.name = REPLACE_TAGS[name].downcase
          else
            return nil
          end
        end

        # check the white list of attributes
        element.attributes.keys.each do |k|
          element.attributes.delete(k) unless DTD_ATTRS[element.name.downcase].include?(k)
        end

        # do cleaning to children
        element.each do |elem|
          unless clean_tags(elem)
            element.delete_element(elem)
          end
        end
      end
      element
    end

    def self.is_xml?(text)
      begin
        doc = REXML::Document.new text
      rescue
        return false
      end
      return (doc && text =~ /</) ? doc : false
    end

    def self.is_enml?(text)
      if doc = is_xml?(text)
        doc.root.instance_of?(REXML::Element) && doc.root.name == 'en-note'
      else
        false
      end
    end
  end

  HTML_HEAD = <<EOT
<!DOCTYPE html>
<html lang="ja" xmlns="http://www.w3.org/1999/xhtml">
<head>
  <meta charset="UTF-8" />
</head>
EOT
end
