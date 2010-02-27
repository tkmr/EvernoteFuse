require File.join(File.dirname(__FILE__), '..', 'evernote', 'evernote_enml.rb')

describe REvernote::ENML do
  before :each do
    @content = 'hello world'
    @enml1 = REvernote::ENML.new(@content)
  end

  describe :new do
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
      enml2 = REvernote::ENML.new(@enml1.xml)
      @enml1.xml.should == enml2.xml
    end

    it 'should accept a REvernote::ENML as ENML and set to @xml' do
      enml2 = REvernote::ENML.new(@enml1)
      @enml1.xml.should == enml2.xml
    end

    it 'should not convert when an argument is ENML string' do
      enml2 = REvernote::ENML.new(@enml1.to_s)
      @enml1.to_s.should == enml2.to_s
    end
  end

  describe :is_enml? do
    it 'should return true when an argument is valid as ENML' do
      REvernote::ENML.is_enml?(@enml1.to_s).should == true
    end

    it 'should not return true when an argument is invalid as ENML' do
      REvernote::ENML.is_enml?("<test><b>hhh</b>").should == false
    end
  end

  describe :to_s do
    it 'should return a string of XML' do
      @enml1.to_s.should == @enml1.xml.to_s
    end

    it 'should convert to valid ENML when it is invalid as ENML' do
      enml1 = REvernote::ENML.new '<p id=\'mybox\'><b>hello</b><textarea>world</textarea><zzz>ok</zzz></p>'
      enml2 = REvernote::ENML.new '<p><b>hello</b><div>world</div></p>'
      enml1.to_s.should  == enml2.to_s
    end
  end
end
