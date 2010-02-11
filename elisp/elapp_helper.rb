module ElAppHelper
  class BufferBase < ElApp
    def initialize(name = nil, mode_name = :fundamental_mode)
      name ||= @@base_name
      @raw_buffer = get_buffer_create(name)
      @mode_name = mode_name
    end

    def switch
      switch_to_buffer @raw_buffer
      el(@mode_name)
    end
  end

  class ModeBase < ElApp
    @@mode_name = :temp_base_mode
    @@name      = "ElAppHelper ModeBase"

    def self.init(option = {})
      mode = self.new
      mode.after_init(option || {})

      #major mode
      mode.define_derived_mode(mode.class.mode_name, :fundamental_mode, mode.class.name, "Major mode for Evernote users") do
        mode.elvar.buffer_read_only = mode.is_readonly?
      end

      #keymap
      keymap_name = (mode.class.mode_name.to_s + "_map").to_sym
      mode.keymaps.each do |key, cmd|
        mode.define_key(keymap_name, key, cmd)
      end

      @@instance = mode
    end

    def self.instance
      @@instance
    end

    def self.mode_name
      @@mode_name
    end

    def self.name
      @@name
    end

    def keymaps
      {}
    end

    def initialize
    end

    def after_init(options)
    end

    def is_readonly?
      true
    end
  end
end
