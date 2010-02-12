require File.join(File.dirname(__FILE__), '..', 'fuse', 'cache_fs.rb')
require 'pathname'

E = EvernoteFS
describe EvernoteFS do
  describe E::CachedFile do
    before :each do
      @callback = E::CachedFile::CallbackMock.new
      @file = E::CachedFile.new('/mnt/test/vi/test.txt', @callback)
    end

    # read ----------------------------------------------------
    describe 'read method' do
      it 'should send :read to the callback object, when it does not cached.' do
        file = E::CachedFile.new('/mnt/test/vi/test4.txt', @callback)
        file.delete

        content = 'hello'
        @callback.stub!(:updated_at).and_return(Time.now - 1000)
        # push to cache
        @callback.should_receive(:read).and_return(content)
        file.read.should == content
        # use cache
        @callback.should_not_receive(:read)
        file.read.should == content
      end
    end

    # write ----------------------------------------------------
    describe 'write method' do
      it 'should send :write to the callback obj' do
        content = 'hello world'
        @callback.should_receive(:write).with(content).and_return(content.upcase)
        @file.write content
        @file.to_s.should == content.upcase
      end

      it 'should cache a data' do
        content = 'hello world'
        @file.write content
        # use cache
        @callback.stub!(:updated_at).and_return(Time.now - 3600)
        @callback.should_not_receive(:read)
        @file.to_s.should == content
      end
    end

    # delete ----------------------------------------------------
    describe 'delete method' do
      it 'should send :delete to the callback obj' do
        file = E::CachedFile.new('/mnt/test/vi/test3.txt', @callback)
        file.write 'test'
        @callback.should_receive(:delete)
        file.delete
      end

      it 'should delete a cache' do
        file = E::CachedFile.new('/mnt/test/vi/test2.txt', @callback)
        file.write 'test'
        file.cache_file.exist?.should == true
        file.delete
        file.cache_file.exist?.should == false
      end
    end

    # cache --------------------------------------------------------
    describe 'cached? method' do
      it 'should return false cache file was empty.' do
        @callback.stub!(:updated_at).and_return(Time.now - 3600)
        @file.write_to_file ''
        @file.cached?.should == false
        @file.write_to_file 'content'
        @file.cached?.should == true
      end

      it 'should return true the resource was updated from cache date' do
        @callback.stub!(:updated_at).and_return(Time.now - 3600)
        @file.write_to_file 'this is content'
        @file.cached?.should == true

        @callback.stub!(:updated_at).and_return(Time.now + 3600)
        @file.cached?.should == false
      end

      it 'should update cache when cached time older than resource.updated time' do
        @callback.stub!(:updated_at).and_return(Time.now + 3600)
        @file.write_to_file 'this is content'
        @file.cached?.should == false
      end
    end
  end

  describe E::CachedDir do
    before :each do
      @callback = E::CachedDir::CallbackMock.new
      @dir = E::CachedDir.new(@callback)
      @file = E::CachedFile.new('/virtual/dir/test.txt', E::CachedFile::CallbackMock.new)
      @content = 'hello world!!!!!'
      @file_name = 'test.txt'
      @dir.write_to(@file_name, @file)
    end

    it 'can add a file, and deltegate to it' do
      @dir.write_to('test.txt', @content)
      @dir.read_file('test.txt').should == @content
      @dir.files['test.txt'].class == E::CachedFile
    end

    describe 'write_to method' do
      it 'should create a new specific object with inserted string' do
        file_name = 'this_is_new_file.txt'
        file_callback = nil
        cache_file = nil

        @callback.should_receive(:new_file).with(file_name, @content).and_return do |name, body|
          file_callback = E::CachedFile::CallbackMock.new
          cache_file = E::CachedFile.new(@dir.new_uuid, file_callback, body.upcase)
        end
        @dir.write_to(file_name, @content)

        file_callback.stub!(:updated_at).and_return(Time.now + 3600)
        file_callback.should_receive(:read)
        @dir.read_file(file_name).should == @content.upcase
      end

      it 'should not do anything if input file is a CachedFile' do
        @file.should_receive(:size).and_return(123)
        dir = E::CachedDir.new
        dir.write_to(@file_name, @file)
        dir.size(@file_name).should == 123
      end
    end

    describe 'delete method' do
      it 'should delete the file' do
        @file.should_receive(:delete)
        @dir.files.has_key?(@file_name).should == true
        @dir.delete(@file_name)
        @dir.files.has_key?(@file_name).should == false
      end
    end

    describe 'mkdir method' do
      before :each do
        @dir_name  = 'new_dir'
        @file_name = 'test_mkdir_spec.txt'
        @content   = 'hello world'
      end

      it 'should create a new directory by callback obj' do
        callback  = nil
        cache_dir = nil

        @callback.should_receive(:new_dir).with(@dir_name).and_return do |name|
          @dir_name.should == name
          callback = E::CachedDir::CallbackMock.new
          cache_dir = E::CachedDir.new(callback)
          cache_dir.write_to(@file_name, @content.upcase)
          cache_dir
        end
        @dir.mkdir(@dir_name)

        file = cache_dir.files[@file_name]
        file.should_receive(:to_s).and_return(file.read)
        @dir.read_file("#{@dir_name}/#{@file_name}").should == @content.upcase
      end

      it 'should not do anything if input file is a CachedDir' do
        @file.should_receive(:size).and_return(123)
        dir = E::CachedDir.new
        dir.write_to(@file_name, @file)
        @dir.mkdir(@dir_name, dir)
        @dir.size("#{@dir_name}/#{@file_name}").should == 123
      end
    end

    describe 'rmdir medhot' do
      it 'should delete the directory and call :delete_dir to callback' do
        dir_name = 'test_dir2'
        @callback.should_receive :delete_dir
        @dir.mkdir dir_name
        @dir.rmdir dir_name
      end
    end

    describe 'size method' do
      it 'should return the file size' do
        @dir.write_to('test.txt', @content)
        @dir.size('test.txt').should == @content.length
        @dir.files['test.txt'].class == E::CachedFile
      end
    end
  end
end
