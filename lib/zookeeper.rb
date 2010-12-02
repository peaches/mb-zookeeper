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


# The base connection class
# @example
#   zk = ZooKeeper.new("localhost:2181")
#   zk.create("/my_path")
class ZooKeeper
  DEFAULTS = {
    :timeout => 10000
  }

  # creates a new locker based on the name you send in
  # @param [String] name the name of the lock you wish to use
  # @see ZooKeeper::Locker#initialize
  # @return ZooKeeper::Locker the lock using this connection and name
  # @example
  #   zk.locker("blah").lock!
  def locker(name)
    Locker.new(self, name)
  end

  # creates a new message queue of name _name_
  # @param [String] name the name of the queue
  # @return [ZooKeeper::MessageQueue] the queue object
  # @see ZooKeeper::MessageQueue#initialize
  # @example
  #   zk.queue("blah").publish({:some_data => "that is yaml serializable"})
  def queue(name)
    MessageQueue.new(self, name)
  end

  # Initialize a new ZooKeeper Client.
  # Can be initialized with a string of the hosts names (see :host argument) otherwise pass a hash with arguments set.
  #
  # @param [String] host string of comma separated ZooKeeper server host:port pairs e.g. "server1:3000, server2:3000"
  # @param optional [Hash] opts the options to create a message with.
  # @option opts [Integer] :timeout The subject
  # @option opts [Object] :watcher (ZooKeeper::EventHandler) an object implementing Watcher interface
  #
  # @example
  #   zk = ZooKeeper.new("localhost:2181")
  #   zk = ZooKeeper.new("localhost:2181,localhost:3000")
  #   zk = ZooKeeper.new(:host => "localhost:2181", :watcher => MyWatcher.new)
  #   zk = ZooKeeper.new(:host => "localhost:2181,localhost:3000", :timeout => 10000, :watcher => :default)
  def initialize(host, opts = {})
    #overidden in native code
  end

  # @return [Boolean] Is connection closed?
  def closed?
    #overidden in native code
  end

  # @return [Boolean] is connection connected?
  def connected?
    #overidden in native code
  end

  # Create a node with the given path. The node data will be the given data, and node acl will be the given acl.  The path is returned.
  #
  # The ephemeral argument specifies whether the created node will be ephemeral or not.
  #
  # An ephemeral node will be removed by the ZooKeeper automatically when the session associated with the creation of the node expires.
  #
  # The sequence argument can also specify to create a sequential node. The actual path name of a sequential node will be the given path plus a suffix "_i" where i is the
  # current sequential number of the node. Once such a node is created, the sequential number will be incremented by one.
  #
  # If a node with the same actual path already exists in the ZooKeeper, a KeeperException with error code KeeperException::NodeExists will be thrown. Note that since
  # a different actual path is used for each invocation of creating sequential node with the same path argument, the call will never throw a NodeExists KeeperException.
  #
  # If the parent node does not exist in the ZooKeeper, a KeeperException with error code KeeperException::NoNode will be thrown.
  #
  # An ephemeral node cannot have children. If the parent node of the given path is ephemeral, a KeeperException with error code KeeperException::NoChildrenForEphemerals
  # will be thrown.
  #
  # This operation, if successful, will trigger all the watches left on the node of the given path by exists and get API calls, and the watches left on the parent node
  # by children API calls.
  #
  # If a node is created successfully, the ZooKeeper server will trigger the watches on the path left by exists calls, and the watches on the parent of the node by children calls.
  #
  # Called with a hash of arguments set.  Supports being executed asynchronousy by passing a callback object.
  #
  # ==== Arguments
  # * <tt>path</tt> -- path of the node
  # * <tt>data</tt> -- initial data for the node
  # * <tt>:acl</tt> -- defaults to ACL::OPEN_ACL_UNSAFE, otherwise the ACL for the node
  # * <tt>:ephemeral</tt> -- defaults to false, if set to true the created node will be ephemeral
  # * <tt>:sequence</tt> -- defaults to false, if set to true the created node will be sequential
  # * <tt>:callback</tt> -- provide a AsyncCallback::StringCallback object or Proc for an asynchronous call to occur
  # * <tt>:context</tt> --  context object passed into callback method
  #
  # ==== Examples
  # ===== create node, ACL will default to ACL::OPEN_ACL_UNSAFE
  #   zk.create(:path => "/path", "foo")
  #   # => "/path"
  #
  # ===== create ephemeral node
  #   zk.create("/path", :mode => :ephemeral)
  #   # => "/path"
  #
  # ===== create sequential node
  #   zk.create("/path", :mode => :persistent_sequence)
  #   # => "/path0"
  #
  # ===== create ephemeral and sequential node
  #   zk.create("/path", "foo", :mode => :ephemeral_sequence)
  #   # => "/path0"
  #
  # ===== create a child path
  #   zk.create("/path/child", "bar")
  #   # => "/path/child"
  #
  # ===== create a sequential child path
  #   zk.create("/path/child", "bar", :mode => :ephemeral_sequence)
  #   # => "/path/child0"
  #
  def create(path, data = "", args = {})
    #overidden in native code
  end

  # Return the data and stat of the node of the given path.
  #
  # If the watch is true and the call is successfull (no exception is thrown), a watch will be left on the node with the given path. The watch will be triggered by a
  # successful operation that sets data on the node, or deletes the node.
  #
  # A KeeperException with error code KeeperException::NoNode will be thrown if no node with the given path exists.
  #
  # Can be called with just the path, otherwise a hash with the arguments set.  Supports being executed asynchronousy by passing a callback object.
  #
  # ==== Arguments
  # * <tt>path</tt> -- path of the node
  # * <tt>:watch</tt> -- defaults to false, set to true if you need to watch this node
  # * <tt>:callback</tt> -- provide a AsyncCallback::DataCallback object or Proc for an asynchronous call to occur
  # * <tt>:context</tt> --  context object passed into callback method
  #
  # ==== Examples
  # ===== get data for path
  #   zk.get("/path")
  #
  # ===== get data and set watch on node
  #   zk.get("/path", :watch => true)
  #
  def get(path, args = {}, &block)
    #overidden in native code
  end


  # Return the stat of the node of the given path. Return nil if no such a node exists.
  #
  # If the watch is true and the call is successful (no exception is thrown), a watch will be left on the node with the given path. The watch will be triggered by
  # a successful operation that creates/delete the node or sets the data on the node.
  #
  # Can be called with just the path, otherwise a hash with the arguments set.  Supports being executed asynchronousy by passing a callback object.
  #
  # ==== Arguments
  # * <tt>path</tt> -- path of the node
  # * <tt>:watch</tt> -- defaults to false, set to true if you need to watch this node
  # * <tt>:callback</tt> -- provide a AsyncCallback::StatCallback object or Proc for an asynchronous call to occur
  # * <tt>:context</tt> --  context object passed into callback method
  #
  # ==== Examples
  # ===== exists for path
  #   zk.exists("/path")
  #   # => ZooKeeper::Stat
  #
  # ===== exists for path with watch set
  #   zk.exists("/path", :watch => true)
  #   # => ZooKeeper::Stat
  #
  # ===== exists for non existent path
  #   zk.exists("/non_existent_path")
  #   # => nil
  #
  def exists?(path, opts = {})
    #overidden in native code
  end

  def close!
    #overidden in native code
  end

  # Set the data for the node of the given path if such a node exists and the given version matches the version of the node (if the given version is -1, it matches any
  # node's versions). Return the stat of the node.
  #
  # This operation, if successful, will trigger all the watches on the node of the given path left by get_data calls.
  #
  # A KeeperException with error code KeeperException::NoNode will be thrown if no node with the given path exists. A KeeperException with error code
  # KeeperException::BadVersion will be thrown if the given version does not match the node's version.
  #
  # Called with a hash of arguments set.  Supports being executed asynchronousy by passing a callback object.
  #
  # ==== Arguments
  # * <tt>:path</tt> -- path of the node
  # * <tt>:data</tt> -- data to set
  # * <tt>:version</tt> -- defaults to -1, otherwise set to the expected matching version
  # * <tt>:callback</tt> -- provide a AsyncCallback::StatCallback object or Proc for an asynchronous call to occur
  # * <tt>:context</tt> --  context object passed into callback method
  #
  # ==== Examples
  #   zk.set("/path", "foo")
  #   zk.set("/path", "foo", :version => 0)
  #
  def set(path, data = "", args = {})
    #overidden in native code
  end

  # Delete the node with the given path. The call will succeed if such a node exists, and the given version matches the node's version (if the given version is -1,
  # it matches any node's versions).
  #
  # A KeeperException with error code KeeperException::NoNode will be thrown if the nodes does not exist.
  #
  # A KeeperException with error code KeeperException::BadVersion will be thrown if the given version does not match the node's version.
  #
  # A KeeperException with error code KeeperException::NotEmpty will be thrown if the node has children.
  #
  # This operation, if successful, will trigger all the watches on the node of the given path left by exists API calls, and the watches on the parent node left by
  # children API calls.
  #
  # Can be called with just the path, otherwise a hash with the arguments set.  Supports being executed asynchronousy by passing a callback object.
  #
  # ==== Arguments
  # * <tt>path</tt> -- path of the node to be deleted
  # * <tt>:version</tt> -- defaults to -1, otherwise set to the expected matching version
  # * <tt>:callback</tt> -- provide a AsyncCallback::VoidCallback object or Proc for an asynchronous call to occur
  # * <tt>:context</tt> --  context object passed into callback method
  #
  # ==== Examples
  #   zk.delete("/path")
  #   zk.delete("/path", :version => 0)
  #
  def delete(path, args = {})
    #overidden in native code
  end

  # Return the list of the children of the node of the given path.
  #
  # If the watch is true and the call is successful (no exception is thrown), a watch will be left on the node with the given path. The watch willbe triggered by a
  # successful operation that deletes the node of the given path or creates/delete a child under the node.
  #
  # A KeeperException with error code KeeperException::NoNode will be thrown if no node with the given path exists.
  #
  # Can be called with just the path, otherwise a hash with the arguments set.  Supports being executed asynchronousy by passing a callback object.
  #
  # ==== Arguments
  # * <tt>path</tt> -- path of the node
  # * <tt>:watch</tt> -- defaults to false, set to true if you need to watch this node
  # * <tt>:callback</tt> -- provide a AsyncCallback::ChildrenCallback object or Proc for an asynchronous call to occur
  # * <tt>:context</tt> --  context object passed into callback method
  #
  # ==== Examples
  # ===== get children for path
  #   zk.create("/path", :data => "foo")
  #   zk.create("/path/child", :data => "child1", :sequence => true)
  #   zk.create("/path/child", :data => "child2", :sequence => true)
  #   zk.children("/path")
  #   # => ["child0", "child1"]
  #
  # ====== get children and set watch
  #   zk.children("/path", :watch => true)
  #   # => ["child0", "child1"]
  #
  def children(path, args = {})
    #overidden in native code
  end

  
end


