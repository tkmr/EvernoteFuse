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

    default_note = {
      :title => 'evernote-note-stub-title',
      :content => @test_note_body,
      :guid => @test_guid,
      :load_content => @test_note_body
    }.stubnize!

    default_notebook = {
      :name => 'evernote-notebook-stub',
      :find_notes => [default_note]
    }.stubnize!

    core = {
      :notebooks => [default_notebook],
      :default_notebook => default_notebook
    }.stubnize!

    REvernote.stub!(:init).and_return(core)
  end

  it 'is exist' do
    EvernoteFS.class.should == Module
  end

  #--------------------------
  describe E::Root do
    before :all do
      @root = E::Root.new(REvernote::DEV_CONF)
      @evernote = @root.core
    end

    it 'has some notebook' do
      @root.contents("").sort.should == @evernote.notebooks.map{|n| n.name }.sort
    end

    #--------------------------
    describe E::Notebook do
      before :all do
        @notebook = @root.subdirs[@evernote.default_notebook.name]
      end

      it 'has some notes' do
        @notebook.contents("").sort.should == @evernote.default_notebook.find_notes.map{|n| n.title }.sort
      end

      #--------------------------
      describe E::Note do
        before :all do
          @note = @notebook.subdirs.first.last
        end

        it 'has some data' do
          @note.read_file('title').should == 'evernote-note-stub-title'
          @note.read_file('content').should == @test_note_body
          @note.read_file('guid').should == @test_guid
        end
      end
    end
  end
end
