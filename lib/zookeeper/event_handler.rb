class ZooKeeper
  class EventHandler
    import org.apache.zookeeper.Watcher if defined?(JZooKeeper)

    attr_accessor :zk

    def initialize(zookeeper_client)
      @zk = zookeeper_client
      @callbacks = Hash.new { |h,k| h[k] = [] }
    end

    def handle_process(event)
      if event.path and !event.path.empty? and @callbacks[event.path]
        @callbacks[event.path].each do |callback|
          callback.call(event, @zk) if callback.respond_to?(:call)
        end
      elsif (!event.path || event.path.empty?) and @callbacks["state_#{event.state}"]
        @callbacks["state_#{event.state}"].each do |callback|
          callback.call(event, @zk) if callback.respond_to?(:call)
        end
      end
    end

    def register(path, &block)
      EventHandlerSubscription.new(self, path, block).tap do |subscription|
        @callbacks[path] << subscription
      end
    end
    alias :subscribe :register

    def register_state_handler(state, &block)
      register("state_#{state}", &block)
    end

    def unregister(subscription)
      ary = @callbacks[subscription.path]
      if index = ary.index(subscription)
        ary[index] = nil
      end
    end
    alias :unsubscribe :unregister
  
    if defined?(JZooKeeper)
      def process(event)
        handle_process(ZooKeeper::WatcherEvent.new(event.type.getIntValue, event.state.getIntValue, event.path))
      end
    else
      def process(event)
        handle_process(event)
      end
    end
  end
end
