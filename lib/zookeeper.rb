if defined?(JRUBY_VERSION)
  require 'zookeeper_j/zookeeper'
else
  require 'zookeeper_c/zookeeper'
end

class ZooKeeper
  DEFAULTS = {
    :timeout => 10000
  }
  
end

require 'zookeeper/id'
require 'zookeeper/permission'
require 'zookeeper/acl'
require 'zookeeper/stat'
require 'zookeeper/keeper_exception'
require 'zookeeper/watcher_event'
require 'zookeeper/locker'
require 'zookeeper/event_handler'
require 'zookeeper/logging'
