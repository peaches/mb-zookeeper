require File.join(File.dirname(__FILE__), %w[spec_helper])

describe ZooKeeper do

  before(:each) do
    @zk = ZooKeeper.new("localhost:2181")
    wait_until { @zk.connected? }
  end

  after(:each) do
      @zk.delete("/_testWatch")
      @zk.close!
      wait_until { !@zk.connected? }
  end

  it "should call back to path registers" do
    locker = Mutex.new
    callback_called = false

    @zk.watcher.register("/_testWatch") do |event, zk|
      locker.synchronize do
        callback_called = true
      end
      event.path.should == "/_testWatch"
    end
    @zk.exists?("/_testWatch", :watch => true)
    @zk.create("/_testWatch", "", :mode => :ephemeral)
    wait_until(5) { locker.synchronize { callback_called } }
    callback_called.should be_true
  end

end
