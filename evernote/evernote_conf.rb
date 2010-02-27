module REvernote
  BASE = File.dirname(__FILE__)

  class Conf
    @@configs = {}
    def initialize conf
      @conf = conf
      specialize(@conf)
    end

    def self.init(yaml_file = nil)
      yaml_file ||= File.join(BASE, 'evernote_conf.yaml')
      @@configs[yaml_file] ||= self.new(YAML.load_file(yaml_file))
    end

    private
    def specialize(h)
      case h.class.name
      when 'Hash'
        h.instance_eval {
          def method_missing(name, *args); self[name.to_sym]; end
        }
        h.each {|k,v| specialize(v) }
      when 'Array'
        h.each {|v|   specialize(v) }
      end
    end

    def method_missing(name, *args)
      @conf[name.to_sym]
    end
  end
end
