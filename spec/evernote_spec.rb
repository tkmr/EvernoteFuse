require File.join(File.dirname(__FILE__), '..', 'evernote.rb')

describe REvernote do
  before :all do
    @core = REvernote::init REvernote::DEV_CONF
  end

  it 'is loaded' do
    REvernote.class.should == Module
    @core.default_notebook.class.should == REvernote::Notebook
  end

  # notebook --------------------------------------------------------------
  describe REvernote::Notebook do
    before :all do
      @notebook = @core.default_notebook
      @new_title = 'this is title'
      @new_body  = 'this is body'
    end

    describe :find_notes do
      it 'should return finded notes' do
        @notebook.find_notes.each do |n|
          n.class.should == REvernote::Note
        end
      end
    end

    describe :get_note do
      it 'should return note' do
        note = @notebook.find_notes.first
        note.guid.should == @notebook.get_note(note.guid).guid
      end
    end

    describe :create_note do
      it 'should add note to evernote' do
        note = REvernote::Note.build(@core, :title => @new_title, :content => @new_body)
        new_note = @notebook.create_note(note)
        got_note = @notebook.get_note(new_note.guid)
        new_note.guid.should == got_note.guid
      end
    end

    # note ---------------------------------------------------------------
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

      describe :build do
        it 'should return new note by title and body' do
          note = REvernote::Note.build(@core, :title => @new_title, :content => @new_body)
          note.title.should == @new_title
          note.content.should == REvernote::ENML.new(@new_body).to_s
        end
      end

      describe :save do
        it 'should call NoteStore.updateNote by my-self' do
          new_title = 'new title is good'
          new_content = 'new content is good'
          note = @notebook.create_note(:title => new_title, :content => new_content)
          note.title = new_title
          note.content = new_content
          note.save

          note2 = @notebook.get_note(note.guid)
          note2.title.should   == new_title
          note2.content.should == REvernote::ENML.new(new_content).to_s

          # it should between from 5 minutes ago to now.
          note2.updated_at.should < Time.now
          note2.updated_at.should > (Time.now - 300)
        end
      end
    end
  end
end

