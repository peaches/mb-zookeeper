class ZooKeeper
  class EventHandlerSubscription
    attr_accessor :event_handler, :path, :callback

    def initialize(event_handler, path, callback)
      @event_handler, @path, @callback = event_handler, path, callback
    end

    def unsubscribe
      @event_handler.unregister(self)
    end
    alias :unregister :unsubscribe
 
    def call(event, zk)
      callback.call(event,zk)
    end

  end
end

