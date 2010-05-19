require 'rubygems'

$LOAD_PATH << "#{File.dirname(__FILE__)}/../ext" << "#{File.dirname(__FILE__)}/../lib"
require 'zookeeper'

unless defined?(JRUBY_VERSION)
  gem 'em-spec'

  require 'eventmachine'
  require "em-spec/rspec"
end

describe ZooKeeper do
  if defined?(JRUBY_VERSION)
    #define this so that EM::Specs done is a no-op in jruby
    def done
    end
  else
    include EM::Spec    
  end
  
  it "should call back to registers" do
    @zk = ZooKeeper.new("localhost:2181", :watcher => :default)    
    @zk.watcher.register("/_testWatch") do |event, zk|
      event.path.should == "/_testWatch"
      zk.close
      done
    end
    @zk.exists?("/_testWatch", :watch => true)
    @zk.create("/_testWatch", "")
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
