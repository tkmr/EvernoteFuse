$KCODE = 'u'
require 'nkf'
require 'evernote.rb'
require 'elapp_helper.rb'

module Evermode
  module Mode
    class EvernoteMode < ElAppHelper::ModeBase
      attr_accessor :main_buffer
      @@mode_name = :evernote_mode
      @@name      = "Evernote"
      @@keymaps   = {'\C-o' => :evermode_test_func}

      def after_init(options)
        defun(:evermode_test_func, :interactive => true) do |x|
          insert_string "hello test func"
          newline
        end
      end

      def keymaps
        super().merge(@@keymaps)
      end

      def insert_with_properties(text, properties)
        prev_point = point
        insert(to_emacs_encode(text))
        set_text_properties(prev_point, point, properties)
      end

      def to_emacs_encode(text)
        NKF.nkf('-e', text)
      end
    end
  end

  def self.core
    @@evernote_core
  end

  @@loaded = false
  def self.init
    unless @@loaded
      @@loaded = true
      @@evernote_core = REvernote::init EVMODE_CONF
      #Mode::EvernoteMode.init
      #Mode::NoteListsMode.init
    end
  end
end

#---------------------------------------------
module Evermode
  module Mode
    class NoteListsMode < EvernoteMode
      @@mode_name = :evernote_note_lists_mode
      @@name      = "Evernote note lists"
      @@keymaps   = {}

      def is_readonly?
        true
      end

      def new_buffer(notebook)
        ElAppHelper::BufferBase.new("*evernote-#{notebook.name}-list*", @@mode_name)
      end

      def after_init(opt)
        @notebooks = {}
        @notebooks['_default_'] = {
          :buffer   => self.new_buffer(Evermode::core.default_notebook),
          :notebook => Evermode::core.default_notebook
        }

        defun(:evermode_go_notes_list, :interactive => true) do |note_name|
          NoteListsMode.instance.go_to(note_name)
        end
      end

      def go_to(note_name)
        target = @notebooks[note_name]
        target[:buffer].switch
        target[:notebook].find_notes.each do |note|
          let('mapper', make_sparse_keymap()) do

            buff = ElAppHelper::BufferBase.new('*helloworld*', @@mode_name)
            define_key(elvar.mapper, '\C-c\C-o') do
              buff.switch
            end

            prop = [:local_map, elvar.mapper, :face, :highlight]
            insert_with_properties(note.title, prop)
          end
          newline
        end
      end
    end
  end
end
