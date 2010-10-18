class ZooKeeper
  class EventHandler
    import org.apache.zookeeper.Watcher if defined?(JRUBY_VERSION)

    attr_accessor :zk

    def initialize(zookeeper_client)
      @zk = zookeeper_client
      @callbacks = {}
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
      @callbacks[path] ||= []
      @callbacks[path] << block
      return @callbacks[path].index(block)
    end

    def register_state_handler(state, &block)
      @callbacks["state_#{state}"] ||= []
      @callbacks["state_#{state}"] << block
      return @callbacks["state_#{state}"].index(block)
    end

    def unregister_state_handler(state, index)
      @callbacks["state_#{state}"][index] = nil 
    end

    def unregister(path, index)
      @callbacks[path][index] = nil
    end

    if defined?(JRUBY_VERSION)
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
