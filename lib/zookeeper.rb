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

    # creates all parent paths and 'path' in zookeeper as nodes with zero data
  # opts should be valid options to ZooKeeper#create
  #
  def mkdir_p(path)
    create(path, '', :mode => :persistent)
  rescue KeeperException::NodeExists
    return
  rescue KeeperException::NoNode
    if File.dirname(path) == '/'
      raise KeeperException, "could not create '/', something is wrong", caller
    end
    mkdir_p(File.dirname(path))
    retry
  end

private
  def handle_chroot_setup(hosts, args = {})
    if matches = hosts.match(%r%\A([-a-zA-Z0-9.]+(?:[:]\d+))(/.*)\Z%)
      host_port, chroot = matches[1], matches[2]
      create_connection(host_port, :watcher => false).tap do |cnx|
        begin
          self.class.mkdir_p(cnx, chroot)
        ensure
          cnx.close
        end
      end
    end
  end

  def create_connection(hosts_str, opts = {})
    self.class.new(hosts_str, opts).tap do |cnx|
      wait_until(45) { cnx.connected? }
      raise ConnectionTimeoutError, "could not connect in #{45} seconds to #{hosts_str.inspect}" unless cnx.connected?
    end
  end

  def wait_until(timeout=10) #&block
    time_to_stop = Time.now + timeout
    until yield do
      break if Time.now > time_to_stop
      sleep 0.3
    end
  end
  
end


