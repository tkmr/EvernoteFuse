require File.join(File.dirname(__FILE__), '..', 'evernote.rb')

describe REvernote do
  before :all do
    @core = REvernote::init REvernote::DEV_CONF
  end

  it 'is loaded' do
    REvernote.class.should == Module
    @core.default_notebook.class.should == REvernote::Notebook
  end

  describe REvernote::Notebook do
    before :all do
      @notebook = @core.default_notebook
    end

    it 'can find notes' do
      @notebook.find_notes.each do |n|
        n.class.should == REvernote::Note
      end
    end

    describe REvernote::Note do
      before :all do
        @notes = @notebook.find_notes
        @note  = @notes.last
      end

      it 'can get content, title, and some more fields' do
        @note.title.length.should > 0
        @note.guid.length.should > 0
      end

      it 'can get content when it loaded' do
        @note.content.should == nil
        @note.load_content()
        @note.content.length.should > 0
      end
    end
  end
end

