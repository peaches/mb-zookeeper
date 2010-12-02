class ZooKeeper
  # event object returned to your subscription blocks
  # @see ZooKeeper::EventHandler#subscribe
  class WatcherEvent
    attr_reader :type, :state, :path

    # :nodoc:
    def initialize(type, state, path) 
      @type, @state, @path = type, state, path
    end
    
    # constants for connection states
    KeeperStateChanged         =  0
    KeeperStateUnknown         = -1
    KeeperStateDisconnected    =  0
    KeeperStateNoSyncConnected =  1
    KeeperStateSyncConnected   =  3
    KeeperStateExpired         = -112

    # constants for event types
    EventNone                  = -1
    EventNodeCreated           = 1
    EventNodeDeleted           = 2
    EventNodeDataChanged       = 3
    EventNodeChildrenChanged   = 4
  end
end
