#$stderr.sync = $stdout.sync = true
require 'rubygems'

$LOAD_PATH << "#{File.dirname(__FILE__)}/../ext" << "#{File.dirname(__FILE__)}/../lib"
require 'zookeeper'

describe ZooKeeper do
  if defined?(JRUBY_VERSION)
    #define this so that EM::Specs done is a no-op in jruby
    def done
    end
  else
    #include EM::Spec
  end
  20.times do |time|
    it "should call back to registers: #{time}" do      
      @zk = ZooKeeper.new("localhost:2181", :watcher => :default)
      @zk.watcher.register("/_testWatch") do |event, zk|
        $stderr.puts("registered callback fired")
        event.path.should == "/_testWatch"
        $stderr.puts("closing")
        zk.close
        wait_until { !@zk.connected? }
        $stderr.puts("stopping")
      end
      $stderr.puts("connecting")
      wait_until { @zk.connected? }
      @zk.exists?("/_testWatch", :watch => true)
      $stderr.puts("creating")
      @zk.create("/_testWatch", "", :mode => :ephemeral)
      sleep 0.25
      @zk.delete("/_testWatch")
      @zk.close
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
