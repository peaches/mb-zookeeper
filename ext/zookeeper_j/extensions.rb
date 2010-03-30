module Zk

  # Map ZooKeeper States and Event Types to Ruby constants
  create_modes = {}
  org.apache.zookeeper.CreateMode.constants.each do |mode|
    enum = org.apache.zookeeper.CreateMode.value_of(mode)
    create_modes[enum] = mode
  end
  CREATE_MODES = create_modes

  connection_states = {}
  org.apache.zookeeper.ZooKeeper::States.constants.each do |state|
    enum = org.apache.zookeeper.ZooKeeper::States.value_of(state)
    connection_states[enum] = state
  end
  CONNECTION_STATES = connection_states

  keeper_states = {}
  org.apache.zookeeper.Watcher::Event::KeeperState.constants.each do |state|
    enum = org.apache.zookeeper.Watcher::Event::KeeperState.value_of(state)
    keeper_states[enum] = state
  end
  KEEPER_STATES = keeper_states

  event_types = {}
  org.apache.zookeeper.Watcher::Event::EventType.constants.each do |event_type|
    enum = org.apache.zookeeper.Watcher::Event::EventType.value_of(event_type)
    event_types[enum] = event_type
  end
  EVENT_TYPES = event_types


  Stat = org.apache.zookeeper.data.Stat
  class Stat
    def to_a
      [getCzxid, getMzxid, getCtime, getMtime, getVersion, getCversion, getAversion, getEphemeralOwner]
    end
  end

  CreateMode = org.apache.zookeeper.CreateMode
  class CreateMode
    def self.to_java(symbol)
        CreateMode.value_of(symbol.to_s.upcase)
    end
  end

  Id = org.apache.zookeeper.data.Id

  ACL = org.apache.zookeeper.data.ACL
  class ACL
    
    def self.to_java(acl)
      ACL.new(acl.permissions, Id.new(acl.id.scheme, acl.id.identification))
    end
     
    def to_ruby
      ZooKeeper::ACL.new(self.getPerms, ZooKeeper::Id.new(self.getId.getScheme, self.getId.getId))
    end

  end
  
  class WatchedEvent < org.apache.zookeeper::WatchedEvent; end
  
  module Watcher
    
    def self.extended(base)
      class << base
        alias_method :process_without_conv, :process
        alias_method :process, :process_with_conv
      end
    end
    
    def process_with_conv(event)
      process_without_conv(WatchedEvent.new(event.type, event.state, event.path))
    end
  end
  
  module AsyncCallback
    # you'd think this would work!!!   how do i refer to nested interface??
    # JavaUtilities.extend_proxy("org.apache.zookeeper.AsyncCallback.StringCallback") do
    #   alias process_result processResult
    # end
  
    module StringCallback
      def processResult(return_code, path, context, name)
        process_result(return_code, path, context, name)
      end
    end
  
    module VoidCallback
      def processResult(return_code, path, context)
        process_result(return_code, path, context)
      end
    end
  
    module StatCallback
      def processResult(return_code, path, context, stat)
        process_result(return_code, path, context, ZooKeeper::Stat.new(stat.to_a))
      end
    end
  
    module ChildrenCallback
      def processResult(return_code, path, context, children)
        process_result(return_code, path, context, children.to_a)
      end
    end
  
    module DataCallback
      def processResult(return_code, path, context, data, stat)
        process_result(return_code, path, context, String.from_java_bytes(data), ZooKeeper::Stat.new(stat.to_a))
      end
    end

    module AclCallback
      def processResult(return_code, path, context, acls, stat)
        process_result(return_code, path, context, acls.collect{|acl| acl.to_ruby}, ZooKeeper::Stat.new(stat.to_a))
      end
    end

  end
  
end

class NativeException
  
  def code
    cause.getCode rescue nil
  end
  
  def message
    cause.getMessage rescue nil
  end
  
end
