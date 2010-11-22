class ZooKeeper
  class EventHandler
    import org.apache.zookeeper.Watcher if defined?(JRUBY_VERSION)

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

    def unregister_state_handler(*args)
      if args.first.is_a?(EventHandlerSubscription)
        unregister(args.first)
      else
        unregister("state_#{args.first}", args[1])
      end
    end

    def unregister(*args)
      if args.first.is_a?(EventHandlerSubscription)
        subscription = args.first
      elsif args.first.is_a?(String) and args[1].is_a?(EventHandlerSubscription)
        subscription = args[1]
      else
        path, index = args[0..1]
        @callbacks[path][index] = nil
        return
      end
      ary = @callbacks[subscription.path]
      if index = ary.index(subscription)
        ary[index] = nil
      end
    end
    alias :unsubscribe :unregister
  
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
