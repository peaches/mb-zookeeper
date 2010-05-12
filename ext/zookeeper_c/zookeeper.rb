require 'zookeeper_c'

class ZooKeeper < CZookeeper

  attr_accessor :watcher

  def initialize(args)
    args  = {:host => args} unless args.is_a?(Hash)
    host    = args[:host]
    # timeout = args[:timeout] || DEFAULTS[:timeout]
    #@watcher = args[:watcher] || DefaultWatcher.new
    # super(host, timeout, watcher)
    super(host)
    @watchers = {} # path => [ block, block, ... ]
  end
  
  def connected?
    state == CONNECTED_STATE
  end
  
  def closed?
    true # we hope TODO fix this
  end
  
  def close
    # TODO
  end

  def watcher(*args)
    puts args.inspect
  end
  
  def create(args)
    path     = args[:path]
    data     = args[:data]
    flags    = 0
    flags    |= EPHEMERAL if args[:ephemeral]
    flags    |= SEQUENCE  if args[:sequence]
    super(path, data, flags)
  end

  def exists(path, watch = true)
    Stat.new(super(path, watch))
  rescue NoNodeError
    return nil
  end
  
  def get(args)
    args  = {:path => args} unless args.is_a?(Hash)
    path     = args[:path]
    watch    = args[:watch] || false
    callback = args[:callback]
    context  = args[:context]
    
    value, stat = super(path)
    [value, Stat.new(stat)]
  rescue NoNodeError
    raise KeeperException::NoNode
  end
  
  def set(args)
    path     = args[:path]
    data     = args[:data]
    version  = args[:version] || -1
    callback = args[:callback]
    context  = args[:context]
  
    super(path, data, version)
  end

  def delete(args)
    args = {:path => args} unless args.is_a?(Hash)
    path     = args[:path]
    version  = args[:version] || -1
    callback = args[:callback]
    context  = args[:context]
    
    super(path, version)
  end

  def children(args)
    args    = {:path => args} unless args.is_a?(Hash)
    path     = args[:path]
    watch    = args[:watch] || false
    callback = args[:callback]
    context  = args[:context]

    ls(path)
  end
  
end
