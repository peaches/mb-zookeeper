require 'zookeeper_c'

$zookeeper_queues = Hash.new

class ZooKeeper < CZookeeper

  attr_accessor :watcher

  def initialize(host, args = {})
    # timeout = args[:timeout] || DEFAULTS[:timeout]
    @watcher =
        if args[:watcher] == :default
          EventHandler.new(self)
        else
          args[:watcher]
        end
    if (@watcher)
      event_queue = Queue.new
      setup_watcher_thread!(event_queue)
    end
    super(host, !!@watcher)
    wait_until(10) { connected? }
    $zookeeper_queues[client_id] = event_queue if @watcher
  end
  
  def connected?
    state == ZOO_CONNECTED_STATE
  end
  
  def closed?
    !connected?
  end
  
  def close!
    @watcher_thread.kill if @watcher_thread
    close
  end
  
  def create(path, data = "", args = {})
    mode = args[:mode] || :ephemeral
    super(path, data, flags_from_mode(mode))
  end

  def exists?(path, args = {})
    watch = args[:watch] || false
    Stat.new(exists(path, watch))
  rescue NoNodeError
    return nil
  end
  
  def get(path, args = {})
    watch    = args[:watch] || false
    #callback = args[:callback]

    value, stat = super(path, watch)
    [value, Stat.new(stat)]
  rescue NoNodeError
    raise KeeperException::NoNode
  end
  
  def set(path, data, args = {})
    version  = args[:version] || -1
#    callback = args[:callback]
#    context  = args[:context]
  
    super(path, data, version)
  end

  def delete(path, args = {})
    version  = args[:version] || -1
    callback = args[:callback]
    context  = args[:context]
    
    super(path, version)
  rescue NoNodeError
    raise KeeperException::NoNode
  end

  def children(path, args = {})
    watch    = args[:watch] || false
    #callback = args[:callback]
    #context  = args[:context]

    get_children(path, watch)
  rescue NoNodeError
    raise KeeperException::NoNode
  end

private
  def flags_from_mode(mode)
    flags = 0 #zero means persistent, non-sequential
    case mode
      when :sequential
        flags |= ZOO_SEQUENCE
      when :persistent_sequential
        flags |= ZOO_SEQUENCE        
      when :ephemeral
        flags |= ZOO_EPHEMERAL
      when :ephemeral_sequential
        flags |= ZOO_SEQUENCE
        flags |= ZOO_EPHEMERAL
    end
    flags
  end

  def wait_until(timeout=10, &block)
    time_to_stop = Time.now + timeout
    until yield do
      break if Time.now > time_to_stop
      sleep 0.3
    end
  end

  def setup_watcher_thread!(event_queue)
    @watcher_thread = Thread.new(self, event_queue) do |zookeeper, queue|
      while(true) do
        begin
          event_hash = queue.pop(true)
          zookeeper.watcher.process(ZooKeeper::WatcherEvent.new(event_hash['type'], event_hash['state'], event_hash['path']))
        rescue ThreadError
          #do nothing
        rescue Exception => e
          $stderr.puts("oh - another real error: \n #{e.inspect} \n #{e.backtrace}")
        ensure
          sleep 0.25
        end
      end
    end
  end
  
end
