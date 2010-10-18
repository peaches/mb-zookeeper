class ZooKeeper
  class ConnectionPool

    def initialize(host, number_of_connections=10, args = {})
      @connection_args = args
      if args[:watcher] and args[:watcher] != :default
        raise "You cannot specify a custom watcher on a connection pool. You will be given an event_handler on each connection"
      else
        @connection_args[:watcher] = :default
      end
      @number_of_connections = number_of_connections
      @host = host
      @pool = ::Queue.new

      populate_pool!
    end

    def close_all!(graceful=false)
      if graceful
        until @pool.num_waiting == 0 do
          sleep 0.1
        end
      else
        raise "Clients are still waiting for this pool" if @pool.num_waiting > 0
      end

      until @pool.size == 0 do
        @pool.pop.close!
      end
    end

    def checkout(blocking = true, &block)
      if block
        checkout_checkin_with_block(block)
      else
        return @pool.pop(!blocking)
      end
    rescue ThreadError
      return false
    end

    def checkin(connection)
      @pool.push(connection)
    end

private

    def populate_pool!
      @number_of_connections.times do
        connection = ZooKeeper.new(@host, @connection_args)
        handler_id = connection.watcher.register_state_handler(WatcherEvent::KeeperStateSyncConnected) do |event, zk|
          checkin(zk)
          connection.watcher.unregister_state_handler(event.state, handler_id)
        end

        # incase we missed the watcher
        if connection.connected?
          connection.watcher.unregister_state_handler(WatcherEvent::KeeperStateSyncConnected, handler_id)
          checkin(connection)
        end
      end
    end

    def checkout_checkin_with_block(block)
      connection = checkout
      block.call(connection)
    ensure
      checkin(connection)
    end

  end
end
