Gem::Specification.new do |s|
  s.name = %q{zookeeper}
  s.version = "0.3"
  s.specification_version = 2 if s.respond_to? :specification_version=
  s.required_rubygems_version = Gem::Requirement.new(">= 0") if s.respond_to? :required_rubygems_version=
  s.authors = ["Shane Mingins", "Topper Bowers"]
  s.date = %q{2010-05-19}
  s.description = %q{A Ruby client interface to the Java ZooKeeper server.}
  s.email = %q{topper@toppingdesign.com}
  s.extra_rdoc_files = ["README"]
  s.files = ["README", "lib/zookeeper.rb", "lib/zookeeper/acl.rb", "lib/zookeeper/id.rb", "lib/zookeeper/keeper_exception.rb",
            "lib/zookeeper/permission.rb", "lib/zookeeper/stat.rb", "lib/zookeeper/watcher_event.rb",
            "lib/zookeeper/event_handler.rb", "lib/zookeeper/locker.rb", "lib/zookeeper/queue.rb", "lib/zookeeper/logging.rb"]
    
  case RUBY_PLATFORM
  when /java/
     s.files += ["ext/zookeeper_j/log4j-1.2.15.jar", "ext/zookeeper_j/zookeeper-3.3.1.jar",
                 "ext/zookeeper_j/extensions.rb", "ext/zookeeper_j/zookeeper.rb"]
     s.platform = 'jruby'
  else
     s.files += ["ext/zookeeper_c/zookeeper_ruby.c", "ext/zookeeper_c/zookeeper.rb", "ext/zookeeper_c/zkc-3.3.1.tar.gz"]
     s.extensions = ["ext/zookeeper_c/extconf.rb"]
  end
  s.homepage = %q{http://github.com/tobowers/zookeeper/tree/master}

  s.rdoc_options = ["--line-numbers", "--inline-source", "--title", "ZooKeeper", "--main", "README"]
  s.require_paths = ["lib", "ext"]
  s.rubygems_version = %q{1.1.0}
  s.summary =  %q{A Ruby client interface to the Java ZooKeeper server.}
end

