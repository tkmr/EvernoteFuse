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
      {:notes => @notes.values, :totalNotes => 230}.stubnize!
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
      @notebooks        = [gen_notebook('default-notebook'),
                           gen_notebook('ro_notebook'),
                           gen_notebook('html_notebook'),
                           gen_notebook('text_notebook')]
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
    FuseFS.stub!(:set_root).and_return(true)
    FuseFS.stub!(:mount_under).and_return(true)
  end

  it 'is exist' do
    EvernoteFS.class.should == Module
  end

  # Root --------------------------
  describe EvernoteFS::Root do
    before :all do
      @root = E::Root.new(EvernoteFS::Conf.connection)
      @evernote = @root.core
      @new_note_title = 'this is a new title'
      @new_note_body  = 'this is a new body'
      @notebook    = @root.subdirs[@evernote.default_notebook.name]

      @ro_notebook   = @root.subdirs['ro_notebook']
      @ro_note       = @ro_notebook.files.values.first

      @html_notebook = @root.subdirs['html_notebook']
      @html_note     = @html_notebook.files.values.first

      @text_notebook = @root.subdirs['text_notebook']
      @text_note     = @text_notebook.files.values.first
    end

    it 'has some notebook' do
      @root.contents("").sort.should == @evernote.notebooks.map{|n| n.name }.sort
    end

    describe :mount do
      it 'should call FuseFS.mount_under and set_root' do
        test_path = '/tmp/everfs/test'
        FuseFS.should_receive(:set_root).with(@root).and_return(true)
        FuseFS.should_receive(:mount_under).with(test_path).and_return(true)
        @root.mount(test_path)
      end
    end

    # Conf --------------------------
    describe EvernoteFS::Conf do
      before :all do
        @config_name = File.join(File.dirname(__FILE__), 'evernote_spec_conf.yaml')
        @config_file  = YAML.load_file(@config_name)
        @default_conf = @config_file[:notebooks][:default]
        EvernoteFS::Conf.init(@config_name)
      end

      it 'should return notebook config when called EvernoteFS::Conf#notebook' do
        EvernoteFS::Conf.notebook('ro_notebook')['cache_limit_sec'].should == @default_conf['cache_limit_sec']
        EvernoteFS::Conf.notebook('ro_notebook')['refresh_interval_sec'].should == @default_conf['refresh_interval_sec']
        EvernoteFS::Conf.notebook('ro_notebook')['note_mode'].should == 'readonly'
        EvernoteFS::Conf.notebook('html_notebook')['note_mode'].should == 'html'
        EvernoteFS::Conf.notebook('text_notebook')['note_mode'].should == 'text'
      end

      it 'should pass configuration to EvernoteFS::Notebook' do
        @notebook.refresh_interval_sec.should == @default_conf['refresh_interval_sec']
        @ro_notebook.note_mode.should   == 'readonly'
        @html_notebook.note_mode.should == 'html'
        @text_notebook.note_mode.should == 'text'
      end

      it 'should pass configuration to EvernoteFS::Note' do
        note = @notebook.files.values.first
        note.cache_limit_sec.should == @default_conf['cache_limit_sec']
        note.note_mode.should == nil
      end
    end

    # Notebook -----------------------
    describe EvernoteFS::Notebook do
      describe :contents do
        it 'has some notes' do
          @notebook.contents("").sort.should == @notebook.files.values.map{|f| f.file_name }.sort
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

        it 'should not add a note when it it exist' do
          t = 'this is my post from my editor!'
          b = 'body body body'

          @core.note_store.should_receive(:createNote).and_return do |token, n|
            @core.note_store.gen_note(n.title, n.content)
          end
          @notebook.write_to(t, b)
          note = @notebook.files[t]

          @core.note_store.should_receive(:updateNote).with(anything, note.note)
          @core.note_store.should_not_receive(:createNote)
          @notebook.write_to(t, 'new body2')

          @core.note_store.should_receive(:updateNote).with(anything, note.note)
          @core.note_store.should_not_receive(:createNote)
          @notebook.write_to(t, 'new body3')

          @notebook.read_file(t).should == REvernote::ENML.new('new body3').to_s
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

        it 'should set valid notebookGuid' do
          file = @text_notebook.write_to('test title', 'test body')
          file.note.notebookGuid.should == @text_notebook.book.guid
        end
      end

      describe 'read_only mode' do
        it 'should include the EvernoteFS::ActsAsReadOnly module when note_mode is "readonly"' do
          @ro_notebook.is_a?(EvernoteFS::ActsAsReadOnly).should == true
          @ro_notebook.can_write?.should == false
        end
      end

      # Note -------------------------
      describe EvernoteFS::Note do
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
            @notebook.read_file(@note.file_name).should == @note.to_s
            new_content = REvernote::ENML.new('this is new content').to_s
            @notebook.write_to(@note.file_name, new_content)
            @notebook.read_file(@note.file_name).should == new_content
          end

          it 'should not modify a Note\'s title' do
            title = 'this_is_title'
            body  = 'this is body'
            @notebook.write_to(title, body)

            # reset
            @notebook.files = {}
            @notebook.load_notes

            file = @notebook.files.values.select{|n| n.note.title == title}.first
            @notebook.files[file.file_name].note.title.should == title
            @notebook.write_to(file.file_name, 'update!!!!')

            @notebook.files = {}
            @notebook.load_notes
            @notebook.files[file.file_name].note.title.should == title
          end
        end

        describe :updated_at do
          it 'should return a Note\'s updated' do
            @note.updated_at.should_not == nil
          end
        end
      end
    end

    # special note -------------------------
    describe EvernoteFS::ActsAsHtmlableNote do
      before :each do
        @title = 'html test note'
        @body  = '<b>this is body</b>'
        @html_notebook.write_to(@title, @body)
      end

      it 'should return a note.content as HTML which is converted from ENML' do
        html = @html_notebook.read_file(@title)
        html.gsub(/\n/, '').should =~ Regexp.new(".*<html.*<body>#{@body}</body></html>")
      end

      it 'should set a HTML to note.content as ENML' do
        html = @html_notebook.read_file(@title)
        new_body = 'hu hu hu hu hu....'
        @html_notebook.write_to(@title, html.gsub(@body, new_body))

        html2 = @html_notebook.read_file(@title)
        html2.gsub(/\n/, '').should =~ Regexp.new(".*<html.*<body><div>#{new_body}</div></body></html>")

        file = @html_notebook.files[@title]
        file.note.content.gsub(/\n/, '').should =~ Regexp.new("<?xml.*<en-note>.*#{new_body}.*</en-note>")
      end
    end

    describe EvernoteFS::ActsAsTextableNote do
      before :each do
        @title = 'text test note'
        @body  = 'this is body'
        @text_notebook.write_to(@title, @body)
      end

      it 'should return a note.content as text which is converted from ENML' do
        text = @text_notebook.read_file(@title)
        text.should == @body
      end

      it 'should set a text to note.content as ENML' do
        text = @text_notebook.read_file(@title)
        new_body = 'hu hu hu hu hu....'
        @text_notebook.write_to(@title, new_body)

        text2 = @text_notebook.read_file(@title)
        text2.gsub(/\n/, '').should == new_body

        file = @text_notebook.files[@title]
        file.note.content.gsub(/\n/, '').should =~ Regexp.new("<?xml.*<en-note><div>#{new_body}</div></en-note>")
      end
    end
  end
end
