require File.join(File.dirname(__FILE__), '..', 'fuse', 'evernote_fs.rb')
require 'pathname'

class Hash
  def stubnize!
    self.each do |k, v|
      self.stub!(k).and_return(v)
    end
  end
end

E = EvernoteFS
describe EvernoteFS do
  before :all do
    #setup evernote stub
    @test_note_body = 'this is the test note body'
    @test_guid = '112233445566778899'

    @default_note = {
      :title => 'evernote-note-stub-title',
      :content => @test_note_body,
      :guid => @test_guid,
      :load_content => @test_note_body,
      :to_uniq_key => "#{@test_guid}-key",
      :updated_at => Time.now
    }.stubnize!

    @default_notebook = {
      :name => 'evernote-notebook-stub',
      :find_notes => [@default_note],
    }.stubnize!

    @default_notebook.stub!(:create_note).and_return do |h|
      hash = @default_note.clone.stubnize!
      hash.stub!(:content).and_return(h[:content])
      hash.stub!(:load_content).and_return(h[:content])
      hash.stub!(:title).and_return(h[:title])
      hash
    end

    @core = {
      :notebooks => [@default_notebook],
      :default_notebook => @default_notebook
    }.stubnize!

    REvernote.stub!(:init).and_return(@core)
  end

  it 'is exist' do
    EvernoteFS.class.should == Module
  end

  # Root --------------------------
  describe E::Root do
    before :all do
      @root = E::Root.new(REvernote::DEV_CONF)
      @evernote = @root.core
      @new_note_title = 'this is a new title'
      @new_note_body  = 'this is a new body'
    end

    it 'has some notebook' do
      @root.contents("").sort.should == @evernote.notebooks.map{|n| n.name }.sort
    end

    # Notebook --------------------------
    describe E::Notebook do
      before :all do
        @notebook = @root.subdirs[@evernote.default_notebook.name]
      end

      describe :contents do
        it 'has some notes' do
          @notebook.contents("").sort.should == @evernote.default_notebook.find_notes.map{|n| n.title }.sort
        end
      end

      describe :write_to do
        it 'should create a new Note and push it to Evernote' do
          note = nil
          @evernote.default_notebook.should_receive(:create_note)
          @notebook.write_to(@new_note_title, @new_note_body)
          @notebook.read_file(@new_note_title).should == @new_note_body
        end
      end

      describe :new_file do
        it 'should return a Note' do
          t = 'new title'
          b = 'new body'
          @notebook.write_to(t, b)

          file = @notebook.files[t]
          file.class.should == EvernoteFS::Note
          file.to_s.should == b
        end
      end

      # Note --------------------------
      describe E::Note do
        before :all do
          @note = @notebook.files[@notebook.files.keys.last]
        end

        describe :to_s do
          it 'should return Note.content' do
            @note.to_s.should == @test_note_body
          end
        end

        describe :write  do
          it 'should update a Note\'s content' do
            new_content = 'this is new content'
            @default_note.should_receive(:save)
            @default_note.stub!(:content=)
            @default_note.stub!(:content).and_return(REvernote::ENML.new(new_content).to_s)

            @notebook.write_to(@default_note[:title], new_content)
          end
        end

        describe :updated_at do
          it 'should return a Note\'s updated' do
            @note.updated_at.should_not == nil
          end
        end
      end
    end
  end
end
