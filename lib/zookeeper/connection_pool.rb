class ZooKeeper
  class ConnectionPool

    def initialize(host, number_of_connections=10, args = {})
      @connection_args = args
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
        @pool.push ZooKeeper.new(@host, @connection_args)
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
