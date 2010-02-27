module REvernote
  class Logger
    class << self
      def init(conf)
        @logger = ::Logger.new(conf[:path])
        @logger.level = conf[:level] || ::Logger::WARN
      end

      def method_missing(name, *args)
        msg = args.first
        if @logger
          if msg.class == Array
            msg.each{|m|  @logger.send(name, "#{m.inspect} --- #{caller.first}")  }
          else
            @logger.send(name, "#{msg.inspect} --- #{caller.first}")
          end
          # logger.send(name, caller.inspect)
        end
      end
    end
  end
end
