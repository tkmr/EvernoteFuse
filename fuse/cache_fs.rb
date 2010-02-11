require 'fusefs'
require 'pathname'
require 'sha1'

module EvernoteFS
  class CachedFile
    module CallbackBase
      def write(body); nil; end
      def read; nil; end
      def delete; nil; end
    end
    class CallbackMock
      include CallbackBase
    end

    TMP_DIR = Pathname.new '/tmp/cache'
    attr_accessor :callback, :real_file

    def initialize(file_name,  callback_obj, content = nil)
      @file_name = file_name
      @real_file = TMP_DIR + (SHA1.hexdigest(file_name) + ".cache")
      @callback  = callback_obj
      @cached    = false
      if content
        self.write_to_file(content)
      end
    end

    def to_s
      self.read
    end

    def size
      @real_file.size
    end

    def read
      unless @cached
        self.write_to_file(callback.read)
      end
      @real_file.read
    end

    def write(body)
      body = callback.write(body) || body
      write_to_file(body)
    end
    def write_to_file(body)
      @real_file.open('w') do |file|
        file << body
      end
      @cached = true
    end

    def delete
      callback.delete
      @real_file.delete
    end
  end

  class CachedDir < FuseFS::MetaDir
    attr_accessor :subdirs, :files

    def size(path)
      base, rest = split_path(path)
      case
      when base.nil?
        nil
      when rest.nil?
        @files[base].size
      else
        @subdirs[base].size(rest)
      end
    end

    def write_to(path,file)
      base, rest = split_path(path)
      if !base.nil? && rest.nil? && @files.has_key?(base)
        @files[base].write(file)
      else
        super
      end
    end

    def delete(path)
      base, rest = split_path(path)
      if !base.nil? && rest.nil? && @files.has_key?(base)
        @files[base].delete
      else
        super
      end
    end
  end
end
