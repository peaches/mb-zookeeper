require File.join(File.dirname(__FILE__), %w[spec_helper])

describe ZooKeeper do

  before(:each) do
    @zk = ZooKeeper.new("localhost:2181", :watcher => :default)
    wait_until { @zk.connected? }
  end

  after(:each) do
      @zk.delete("/_testWatch")
      @zk.close!
      wait_until { !@zk.connected? }
  end

  it "should call back to path registers" do
    callback_called = false

    @zk.watcher.register("/_testWatch") do |event, zk|
      callback_called = true
      event.path.should == "/_testWatch"
    end
    @zk.exists?("/_testWatch", :watch => true)
    @zk.create("/_testWatch", "", :mode => :ephemeral)
    sleep 0.3
    callback_called.should be_true
  end

  def wait_until(timeout=10, &block)
    time_to_stop = Time.now + timeout
    until yield do
      break if Time.now > time_to_stop
      sleep 0.3
    end
  end


end
