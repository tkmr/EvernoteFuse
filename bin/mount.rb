#!/usr/bin/env ruby
require File.join(File.dirname(__FILE__), '..', 'fuse', 'evernote_fs.rb')

target_path = ARGV.shift
raise 'Argument error! set a mount point' unless target_path

# mount.
root = EvernoteFS::Root.new(EvernoteFS::Conf.connection)
root.mount(target_path)

# trap exit()
END {
  system("sudo umount #{target_path}")
}
FuseFS.run


