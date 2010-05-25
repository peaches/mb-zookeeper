class ZooKeeper
  class Locker

    attr_accessor :zk
    
    def initialize(zookeeper_client, path, root_lock_node = "/_zklocking")
      @zk = zookeeper_client
      @root_lock_node = root_lock_node
      @path = path
      if !@zk.exists?(root_lock_node)
        @zk.create(root_lock_node, "", :mode => :persistent)
      end
    end

    def lock!
      path = lock_path(@path)
      if !@zk.exists?(path)
        @zk.create(path, "", :mode => :persistent)
      end
      @lock_file = @zk.create("#{path}/lock", "", :mode => :ephemeral_sequential)
      lock_files = @zk.children(path)
      lock_files.sort! {|a,b| digit_from_lock_file(a) <=> digit_from_lock_file(b)}
      if digit_from_lock_file(lock_files.first) == digit_from_lock_file(@lock_file)
        @locked = true
        return true
      else
        @zk.delete(@lock_file)
        return false
      end
    end

    def unlock!
      if @locked
        @zk.delete(@lock_file)
        if @zk.children(lock_path(@path)).empty?
          begin
            @zk.delete(lock_path(@path))
          rescue
            nil
          end
        end
        @locked = false
        return true
      end
    end

    def lock_path(path)
      "#{@root_lock_node}/#{path.gsub("/", "__")}"
    end

    def digit_from_lock_file(lock_path)
      lock_path[/\d+$/].to_i
    end

  end
end
