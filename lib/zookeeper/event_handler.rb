class ZooKeeper
  class EventHandler
    import org.apache.zookeeper.Watcher if defined?(JRUBY_VERSION)

    def initialize(zookeeper_client)
      @zk = zookeeper_client
      @callbacks = {}
    end

    def handle_process(event)
      if event.path and @callbacks[event.path]
        @callbacks[event.path].each do |callback|
          callback.call(event)
        end
      end
    end

    def register(path, &block)
      @callbacks[path] ||= []
      @callbacks[path] << block
    end

    if defined?(JRUBY_VERSION)
      def process(event)
        handle_process(ZooKeeper::WatcherEvent.new(event.get_type, event.get_state, event.get_path))
      end
    else
      def process(event)
        handle_process(event)
      end
    end
  end
end
