class ZooKeeper
  # useful class for locking.
  # implements a locking algorithm talked about by Zookeeper documentation
  # @see http://hadoop.apache.org/zookeeper/docs/r3.0.0/recipes.html#sc_recipes_Locks Zookeeper docs
  class Locker

    # @private
    attr_accessor :zk

    # @private
    def initialize(zookeeper_client, name, root_lock_node = "/_zklocking")
      @zk = zookeeper_client
      @root_lock_node = root_lock_node
      @path = name
      @zk.create(root_lock_node, "", :mode => :persistent) rescue KeeperException::NodeExists
    end

    # a blocking lock that waits until the lock is available for continuing
    # @param [Block] the block you want to execute once your client has
    #   received the lock
    # @example
    #   zk.locker("boooyah").with_lock do
    #     #some logic
    #   end
    def with_lock(&blk)
      create_lock_file!
      queue = Queue.new

      first_lock_blk = lambda do
        if have_first_lock?(true)
           queue << :locked
         end
      end

      @zk.watcher.register(root_lock_path, &first_lock_blk)
      first_lock_blk.call

      if queue.pop
        begin
          @locked = true
          return blk.call
        ensure
          unlock!
        end
      end

    end

    # a non-blocking lock
    # returns false if your client did not receive the lock
    # requires calling #unlock! if you *did* get the lock.
    # @see ZooKeeper::Locker#unlock!
    # @see ZooKeeper::Locker#with_lock
    # @example
    #   locker = zk.locker("booyah")
    #   locker.lock! # => true or false depending on if you got the lock or not
    #   locker.unlock!
    def lock!
      create_lock_file!
      if have_first_lock?(false)
        @locked = true
      else
        cleanup_lock_file!
        false
      end
    end

    # unlock the lock you have
    # @example
    #   locker = zk.locker("booyah")
    #   locker.lock!
    #   locker.unlock!
    def unlock!
      if @locked
        cleanup_lock_file!
        @locked = false
        true
      end
    end

private

    def cleanup_lock_file!
      @zk.delete(@lock_file)
      @zk.delete(root_lock_path) rescue KeeperException::NotEmpty
    end

    def have_first_lock?(watch = true)
      lock_files = @zk.children(root_lock_path, :watch => watch)
      lock_files.sort! {|a,b| digit_from_lock_file(a) <=> digit_from_lock_file(b)}
      digit_from_lock_file(lock_files.first) == digit_from_lock_file(@lock_file)
    end

    def create_lock_file!
      @zk.create(root_lock_path, "", :mode => :persistent) rescue KeeperException::NodeExists
      @lock_file = @zk.create("#{root_lock_path}/lock", "", :mode => :ephemeral_sequential)
    rescue KeeperException::NoNode
      retry
    end

    def root_lock_path
      "#{@root_lock_node}/#{@path.gsub("/", "__")}"
    end

    def digit_from_lock_file(lock_path)
      lock_path[/\d+$/].to_i
    end

  end
end
