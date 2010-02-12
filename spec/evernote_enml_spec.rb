require File.join(File.dirname(__FILE__), '..', 'evernote_enml.rb')

describe REvernote::ENML do
  describe :new do
    before :all do
      @content = 'hello world'
    end

    it 'should accept a string and convert to the ENML' do
      enml = REvernote::ENML.new(@content)
      enml.xml.root.to_s.should == "<en-note><div>#{@content}</div></en-note>"
    end

    it 'should accept a REXML::Element and wrap ENML document' do
      elem = REXML::Element.new 'strong'
      elem.add REXML::Text.new @content
      enml = REvernote::ENML.new(elem)
      enml.xml.root.to_s.should == "<en-note><strong>#{@content}</strong></en-note>"
    end

    it 'should accept a REXML::Document as ENML and set to @xml' do
      enml1 = REvernote::ENML.new(@content)
      enml2 = REvernote::ENML.new(enml1.xml)
      enml2.xml.root.to_s.should == "<en-note><div>#{@content}</div></en-note>"
      enml1.xml.should == enml2.xml
    end
  end
end
