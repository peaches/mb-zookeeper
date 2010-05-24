class ZooKeeper
  class EventHandler
    import org.apache.zookeeper.Watcher if defined?(JRUBY_VERSION)

    attr_accessor :zk

    def initialize(zookeeper_client)
      @zk = zookeeper_client
      @callbacks = {}
    end

    def handle_process(event)
      if event.path and @callbacks[event.path]
        @callbacks[event.path].each do |callback|
          callback.call(event, @zk) if callback.respond_to?(:call)
        end
      end
    end

    def register(path, &block)
      @callbacks[path] ||= []
      @callbacks[path] << block
      return @callbacks[path].index(block)
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
