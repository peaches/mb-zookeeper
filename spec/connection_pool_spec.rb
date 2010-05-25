require File.join(File.dirname(__FILE__), %w[spec_helper])

describe ZooKeeper::ConnectionPool do

  before(:each) do
    @pool_size = 2
    @connection_pool = ZooKeeper::ConnectionPool.new("localhost:2181", @pool_size)
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
    @pool_size.times do
      connections << @connection_pool.checkout(false)
    end
    @connection_pool.checkout(false).should be_false
    connections.each do |connection|
      @connection_pool.checkin(connection)
    end
  end

end
