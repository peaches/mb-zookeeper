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

  20.times do |time|
    it "should call back to registers: #{time}" do      
      callback_called = false
      @zk.watcher.register("/_testWatch") do |event, zk|
        event.path.should == "/_testWatch"
        callback_called = true
      end
      @zk.exists?("/_testWatch", :watch => true)
      @zk.create("/_testWatch", "", :mode => :ephemeral)
      sleep 0.3
      callback_called.should be_true
    end
  end

  def wait_until(timeout=10, &block)
    time_to_stop = Time.now + timeout
    until yield do
      break if Time.now > time_to_stop
      sleep 0.3
    end
  end


end

#describe ZooKeeper do
#
#  before(:each) do
#    @zk = ZooKeeper.new("localhost:2181", :watcher => EM.spawn{})
#    wait_until{ @zk.connected? }
#  end
#
#  after(:each) do
#    @zk.close
#    wait_until{ !@zk.connected? }
#  end
#
#  it "should be cool" do
#    @zk.exists?("/_testWatch", :watch => true)
#    @zk.create("/_testWatch", "")
#  end
#
#end
