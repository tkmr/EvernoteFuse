module EvernoteFS
  class Conf < REvernote::Conf
    class << self
      def init(yaml_file = nil)
        conf = super(yaml_file)
        REvernote::Logger.init(conf.logger)
        conf
      end

      def notebook(notebook_name)
        unless @notebooks_conf_cache && @notebooks_conf_cache[notebook_name]
          @notebooks_conf_cache ||= {}
          @notebooks_conf_cache[notebook_name] ||= main_conf.notebooks[:default].merge(main_conf.notebooks[notebook_name] || {})
        end
        @notebooks_conf_cache[notebook_name]
      end

      def connection
        main_conf.connection
      end

      def main_conf
        @main_conf ||= init()
      end
    end
  end
end
