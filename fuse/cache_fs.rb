require 'rubygems'
require 'fusefs'
require 'pathname'
require 'sha1'
require 'uuidtools'

#    module CallbackBase
#      def act_write(body); nil; end
#      def act_read; nil; end
#      def act_delete; nil; end
#      def updated_at; nil; end
#    end
#    module CallbackBase
#      def new_file(file_name, content); nil; end
#      def new_dir(dir_name); nil; end
#      def delete_dir(dir_name); nil; end
#    end

module EvernoteFS
  class CachedFile
    module CallbackBase
      def act_write(body); nil; end
      def act_read; nil; end
      def act_delete; nil; end
      def updated_at; nil; end
    end

    class CallbackMock
      include CallbackBase
    end

    TMP_DIR = Pathname.new '/tmp/cache'
    TMP_DIR.mkpath
    attr_accessor :callback, :cache_file, :cache_limit_sec

    def initialize(uniq_name,  callback_obj = nil, content = nil)
      @cache_limit_sec = nil
      @cache_file = TMP_DIR + (SHA1.hexdigest(uniq_name) + ".cache")
      @callback  = callback_obj || CallbackMock.new
      if content
        self.write_to_file(content.to_s)
      end
    end

    def cached?
      cache_exist = @cache_file.exist? ? @cache_file.size > 0 : false
      modified    = @callback.updated_at
      cache_exist && !expired? && (modified.nil? || modified < @cache_file.mtime)
    end

    def expired?
      @cache_limit_sec && (@cache_file.mtime + @cache_limit_sec.to_i) <= Time.now
    end

    def size
      @cache_file.size
    end

    def to_s; read; end
    def read
      unless cached?
        content = callback.act_read
        write_to_file(content) if content && content.length > 0
      end
      @cache_file.exist? ? @cache_file.read : nil
    end

    def write(body)
      body = callback.act_write(body) || body
      write_to_file(body)
    end

    def write_to_file(body)
      @cache_file.open('w') do |file|
        file << body
      end
    end

    def delete
      callback.act_delete
      @cache_file.delete if @cache_file.exist?
    end
  end


  class CachedDir < FuseFS::MetaDir
    module CallbackBase
      def new_file(file_name, content); nil; end
      def new_dir(dir_name); nil; end
      def delete_dir(dir_name); nil; end
    end

    class CallbackMock
      include CallbackBase
    end

    attr_accessor :subdirs, :files
    def initialize(callback_obj = nil)
      super()
      @callback = callback_obj || CallbackMock.new
    end

    def size(path)
      base, rest = split_path(path)
      if base.nil?
        nil
      elsif rest.nil?
        @files.has_key?(base) ? @files[base].size : nil
      else
        @subdirs[base].size(rest)
      end
    end

    def write_to(path,file)
      base, rest = split_path(path)
      if base.nil?
        false
      elsif !rest.nil?
        super
      elsif file.is_a?(CachedFile)
        @files[base] = file
      elsif @files.has_key?(base)
        @files[base].write(file)
      else
        @files[base] = @callback.new_file(base, file) || CachedFile.new(new_uuid, nil, file)
      end
    end

    def mkdir(path,dir=nil)
      base, rest = split_path(path)
      if base.nil?
        false
      elsif !rest.nil?
        super
      elsif @subdirs.has_key?(base)
        false
      elsif dir && dir.is_a?(CachedDir)
        @subdirs[base] = dir
      else
        @subdirs[base] = @callback.new_dir(base) || CachedDir.new
      end
    end

    def rmdir(path)
      base, rest = split_path(path)
      if (!base.nil?) && rest.nil? && @subdirs.has_key?(base) && @subdirs[base].is_a?(CachedDir)
        @subdirs[base].rmdir_self
        @callback.delete_dir(base)
      end
      super
    end

    def rmdir_self
      true
    end

    def delete(path)
      base, rest = split_path(path)
      if !base.nil? && rest.nil? && @files.has_key?(base)
        @files[base].delete
      end
      super
    end

    def new_uuid
      UUIDTools::UUID.random_create.to_s
    end

    def self.new_uuid
      instance.new_uuid
    end

    def self.instance
      @@instance ||= self.new
    end
  end
end
