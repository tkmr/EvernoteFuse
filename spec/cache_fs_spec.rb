require File.join(File.dirname(__FILE__), '..', 'fuse', 'cache_fs.rb')
require 'pathname'

E = EvernoteFS
describe EvernoteFS do
  describe E::CachedFile do
    before do
      @file = E::CachedFile.new('/mnt/test/vi/test.txt', E::CachedFile::CallbackMock.new)
    end

    it 'can write and read a file' do
      content = 'hello world\n'
      @file.write content
      @file.to_s.should == content
    end

    it 'can delete a file' do
      @file.write 'test'
      @file.delete
      @file.real_file.exist?.should == false
    end

    it 'should cache data when called :write method' do
      pending
    end

    it 'will do it only one-time, that call :read method to the callback object when it does not cached.' do
      pending
    end

    it 'should pop cache when self.cached time > callback object.updated time' do
      pending
    end
  end

  describe E::CachedDir do
    before do
      @dir = E::CachedDir.new
      @file = E::CachedFile.new('/virtual/dir/test.txt', E::CachedFile::CallbackMock.new)
      @content = 'hello world!!!!!'
      @dir.write_to('test.txt', @file)
    end

    it 'can add a file, and deltegate to it' do
      @dir.write_to('test.txt', @content)
      @dir.read_file('test.txt').should == @content
      @dir.files['test.txt'].class == E::CachedFile
    end

    it 'can get the file size' do
      @dir.write_to('test.txt', @content)
      @dir.size('test.txt').should == @content.length
      @dir.files['test.txt'].class == E::CachedFile
    end

    it 'should return correct permission' do
      pending
    end
  end
end
