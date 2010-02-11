require 'test/unit'
require "evernote-mode.rb"

class TestEvernote < Test::Unit::TestCase
  def setup
    ::Evermode::init
  end

  def teardown

  end

  def test_goto_default
    evermode_go_notes_list('_default_')
    assert_equal(buffer_name(), "*evernote-#{Evermode::core.default_notebook.name}-list*")
  end
end
