ZOOKEEPER_ROOT = File.expand_path(File.join(File.dirname(__FILE__), '..'))

if defined?(JRUBY_VERSION)
  require "#{ZOOKEEPER_ROOT}/ext/zookeeper_j/zookeeper"
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
require 'zookeeper/message_queue'
require 'zookeeper/event_handler_subscription'
require 'zookeeper/event_handler'
require 'zookeeper/connection_pool'
require 'zookeeper/logging'

class ZooKeeper
  DEFAULTS = {
    :timeout => 10000
  }

  def locker(path)
    Locker.new(self, path)
  end

  def queue(name)
    MessageQueue.new(self, name)
  end
  
end


