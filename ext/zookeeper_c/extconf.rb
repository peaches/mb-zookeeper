require 'mkmf'
require 'rbconfig'

HERE = File.expand_path(File.dirname(__FILE__))
BUNDLE = Dir.glob("zkc-*.tar.gz").first
BUNDLE_PATH = "c"

if ENV['DEBUG']
  puts "Setting debug flags."
  $EXTRA_CONF = " --enable-debug"
end

$includes = " -I#{HERE}/include"
$libraries = " -L#{HERE}/lib"
$CFLAGS = "#{$includes} #{$libraries} "

$LDFLAGS = "#{$libraries} "
$LIBPATH = ["#{HERE}/lib"]
$DEFLIBPATH = []

Dir.chdir(HERE) do
  puts "chdir to: #{HERE}"                                         
  puts "Building zkc."
  puts(cmd = "tar xzf #{BUNDLE} 2>&1")
  raise "'#{cmd}' failed" unless system(cmd)

  Dir.chdir(BUNDLE_PATH) do
    config_cmd = ["./configure --prefix=#{HERE} --disable-dependency-tracking"]

    config_cmd << '--disable-shared' if Config::CONFIG['target_os'] != 'linux'

    config_cmd << "#{$EXTRA_CONF} 2>&1"

    puts(cmd = config_cmd.join(' '))
    raise "'#{cmd}' failed" unless system(cmd)
    puts(cmd = "make -d 2>&1")
    raise "'#{cmd}' failed" unless system(cmd)
    puts(cmd = "make install 2>&1")
    raise "'#{cmd}' failed" unless system(cmd)
  end

  system("rm -rf #{BUNDLE_PATH}") unless ENV['DEBUG'] or ENV['DEV']
end

# Absolutely prevent the linker from picking up any other zookeeper_mt
Dir.chdir("#{HERE}/lib") do
  system("cp -f libzookeeper_mt.a libzookeeper_mt_gem.a") 
  system("cp -f libzookeeper_mt.la libzookeeper_mt_gem.la") 
end
$LIBS << " -lzookeeper_mt_gem"

if ENV['DEBUG']
  $CFLAGS = " -g gdb3"
end

#if have_library("zookeeper_mt") then
  create_makefile('zookeeper_c')
#else
#  puts "No ZooKeeper C client library available"
#end
