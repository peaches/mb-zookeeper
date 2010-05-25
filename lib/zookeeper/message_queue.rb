class ZooKeeper
  class MessageQueue

    attr_accessor :zk

    def initialize(zookeeper_client, queue_name, queue_root = "/_zkqueues")
      @zk = zookeeper_client
      @queue = queue_name
      @queue_root = queue_root
      @zk.create(@queue_root, "", :mode => :persistent) unless @zk.exists?(@queue_root)
      @zk.create(full_queue_path, "", :mode => :persistent) unless @zk.exists?(full_queue_path)
    end

    def find_and_process_next_available(messages)
      messages.sort! {|a,b| digit_from_path(a) <=> digit_from_path(b)}
      messages.each do |message_title|
        message_path = "#{full_queue_path}/#{message_title}"
        locker = @zk.locker(message_path)
        if locker.lock!
          begin
            data = @zk.get(message_path).first
            result = @subscription_block.call(message_title, data)
            @zk.delete(message_path) if result
          ensure
            locker.unlock!
          end
        end
      end
    end

    def publish(data, message_title = nil)
      mode = :persistent_sequential
      if message_title
        mode = :persistent
      else
        message_title = "message"
      end
      @zk.create("#{full_queue_path}/#{message_title}", data, :mode => mode)
    rescue KeeperException::NodeExists
      return false
    end
    
    def messages
      @zk.children(full_queue_path)
    end
    
    def delete_message(message_title)
      full_path = "#{full_queue_path}/#{message_title}"
      locker = @zk.locker("#{full_queue_path}/#{message_title}")
      if locker.lock!
        begin
          @zk.delete(full_path)
          return true
        ensure
          locker.unlock!
        end
      else
        return false
      end
    end
    
    def poll!
      find_and_process_next_available(@zk.children(full_queue_path))
    end

    #subscribe like subscribe {|title, data| handle_message!; return true}
    #returning true in the block deletes the message, false unlocks and requeues
    def subscribe(&block)
      @subscription_block = block
      watch = false
      if @zk.watcher
        watch = true 
        @subscription_reference = @zk.watcher.register(full_queue_path) do |event, zk|
          if event.type == WatcherEvent::EventNodeChildrenChanged
            find_and_process_next_available(@zk.children(full_queue_path, :watch => watch))
          end
        end
      end
      find_and_process_next_available(@zk.children(full_queue_path, :watch => watch))
    end

    def unsubscribe
      @zk.watcher.unregister(full_queue_path, @subscription_reference) if @zk.watcher  
    end

    #highly destructive method!
    def destroy!
      children = @zk.children(full_queue_path)
      locks = []
      children.each do |path|
        lock = @zk.locker("#{full_queue_path}/#{path}")
        lock.lock!
        locks << lock
      end
      children.each do |path|
        @zk.delete("#{full_queue_path}/#{path}")
      end
      @zk.delete(full_queue_path)
      locks.each do |lock|
        lock.unlock!
      end
    end

    def full_queue_path
      @full_queue_path ||= "#{@queue_root}/#{@queue}"
    end

    def digit_from_path(path)
      path[/\d+$/].to_i
    end

  end
end
