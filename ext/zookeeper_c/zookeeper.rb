require 'zookeeper_c'

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
    local_watcher = @watcher
    spawned_watcher = nil
    if (@watcher)
      raise "you must use eventmachine if you want a watcher in MRI" unless defined?(EM)
      spawned_watcher = EM.spawn do |event_hash|
        local_watcher.process(ZooKeeper::WatcherEvent.new(event_hash["type"], event_hash["state"], event_hash["path"]))
      end
    end
    # super(host, timeout, watcher)
    super(host, spawned_watcher)
  end
  
  def connected?
    state == ZOO_CONNECTED_STATE
  end
  
  def closed?
    !connected?
  end
  
  def close
    if connected? and !@close_requested
      @close_requested = true
      super
    end
  end

  def handle_watcher_event(*args)
    @watcher.process(ZooKeeper::WatcherEvent.new(*args)) if @watcher
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
    callback = args[:callback]
    context  = args[:context]
  
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
  
end
