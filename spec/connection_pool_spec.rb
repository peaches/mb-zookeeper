require File.join(File.dirname(__FILE__), %w[spec_helper])

describe ZooKeeper::ConnectionPool do

  before(:each) do
    @pool_size = 2
    @connection_pool = ZooKeeper::ConnectionPool.new("localhost:2181", @pool_size, :watcher => :default)
  end

  after(:each) do
    @connection_pool.close_all!  
  end

  it "should allow you to execute commands on a connection" do
    @connection_pool.checkout do |zk|
      zk.create("/test_pool", "", :mode => :ephemeral)
      zk.exists?("/test_pool").should be_true
    end
  end

  it "using non-blocking it should only let you checkout the pool size" do
    connections = []
    wait_until {
      @connection_pool.checkout(false)
    }
    (@pool_size - 1).times do
      connections << @connection_pool.checkout(false)
    end
    @connection_pool.checkout(false).should be_false
  end
  
  it "should allow watchers still" do
    callback_called = false
    @connection_pool.checkout do |zk|
      zk.watcher.register("/_testWatch") do |event, zk|
        callback_called = true
        event.path.should == "/_testWatch"
      end
      zk.exists?("/_testWatch", :watch => true)
    end
    @connection_pool.checkout {|zk| zk.create("/_testWatch", "", :mode => :ephemeral) }
    sleep 0.3
    callback_called.should be_true
  end

end
