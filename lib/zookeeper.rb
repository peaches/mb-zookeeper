if defined?(JRUBY_VERSION)
  require 'zookeeper_j/zookeeper'
else
  require 'zookeeper_c/zookeeper'
end

require 'zookeeper/id'
require 'zookeeper/permission'
require 'zookeeper/acl'
require 'zookeeper/stat'
require 'zookeeper/keeper_exception'
require 'zookeeper/watcher_event'
require 'zookeeper/locker'
require 'zookeeper/queue'
require 'zookeeper/event_handler'
require 'zookeeper/logging'

class ZooKeeper
  DEFAULTS = {
    :timeout => 10000
  }

  def locker(path)
    Locker.new(self, path)
  end

  def queue(name)
    Queue.new(self, name)
  end
  
end


