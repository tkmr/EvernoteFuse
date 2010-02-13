require File.join(File.dirname(__FILE__), '..', 'fuse', 'evernote_fs.rb')
require 'pathname'

class Hash
  def stubnize!
    self.each do |k, v|
      self.stub!(k).and_return(v)
    end
  end
end

# for test..
class EverMock
  class NoteStore
    attr_accessor :notes

    def initialize
      note = gen_note('default-note-title', 'default-note-body')
      @notes = {}
      @notes[note.guid] = note
    end

    def findNotes(t, f, o, m)
      {:notes => @notes.values}.stubnize!
    end

    def getNoteContent(t, guid)
      @notes[guid].content
    end

    def getNote(t, g, *arg)
      @notes[g]
    end

    def createNote(t, base)
      note = gen_note(base.title, base.content)
      @notes[note.guid] = note
      note
    end

    def updateNote(t, note)
      @notes[note.guid] = note
    end

    def gen_note(title, body)
      Evernote::EDAM::Type::Note.new(:title => title,
                                     :content => body,
                                     :guid => (rand*10000000).to_i,
                                     :updated => Time.now.to_i + 3000)
    end
  end

  class Core
    attr_accessor :note_store, :default_notebook, :notebooks, :auth_token
    def initialize
      @note_store       = NoteStore.new
      @notebooks        = [gen_notebook('default-notebook')]
      @default_notebook = @notebooks.first
      @auth_token       = 'dkdkdkdkdkdkdkdkdkd'
    end
    def gen_notebook(name)
      nb = REvernote::Notebook.new(Evernote::EDAM::Type::Notebook.new(:name => name), self)
      nb.convert_and_push_note gen_note("title #{(rand*10000).to_i}", "content #{(rand*10000).to_i}")
      nb.convert_and_push_note gen_note("title #{(rand*10000).to_i}", "content #{(rand*10000).to_i}")
      nb
    end
    def gen_note(title, body)
      Evernote::EDAM::Type::Note.new(:title => title,
                                     :content => body,
                                     :guid => (rand*10000000).to_i,
                                     :updated => Time.now.to_i)
    end
  end
end

E = EvernoteFS
describe EvernoteFS do
  before :all do
    #mock
    @core = EverMock::Core.new
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

    # Notebook -----------------------
    describe E::Notebook do
      before :each do
        @notebook = @root.subdirs[@evernote.default_notebook.name]
      end

      describe :contents do
        it 'has some notes' do
          @notebook.contents("").sort.should == @evernote.default_notebook.find_notes.map{|n| n.title }.sort
        end
      end

      describe :write_to do
        it 'should create a new Note and push it to Evernote' do
          title = 'hu hu hu hu'
          @notebook.write_to(title, @new_note_body)
          @notebook.read_file(title).should == REvernote::ENML.new(@new_note_body).to_s
        end

        it 'should accept a EvernoteFS::Note' do
          note = @notebook.files.values.first
          note.to_s
          note.class.should == EvernoteFS::Note

          title = 'test EvernoteFS::Note'
          @notebook.write_to(title, note)
          @notebook.read_file(title).should == note.to_s
        end
      end

      describe :new_file do
        it 'should return a Note' do
          t = 'new title'
          b = 'new body'
          @notebook.write_to(t, b)

          file = @notebook.files[t]
          file.class.should == EvernoteFS::Note
          file.to_s.should == REvernote::ENML.new(b).to_s
        end
      end

      # Note --------------------------
      describe E::Note do
        before :each do
          @note = @notebook.files[@notebook.files.keys.last]
          @note.read
        end

        describe :to_s do
          it 'should return Note.content' do
            @note.write('hello this is test content')
            @note.to_s.should == @note.note.content
          end
        end

        describe :write  do
          it 'should update a Note\'s content' do
            @notebook.read_file(@note.note.title).should == @note.to_s
            new_content = REvernote::ENML.new('this is new content').to_s
            @notebook.write_to(@note.note.title, new_content)
            @notebook.read_file(@note.note.title).should == new_content
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
