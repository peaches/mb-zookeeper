require File.join(File.dirname(__FILE__), %w[spec_helper])

describe ZooKeeper::MessageQueue do

  before(:each) do
    @zk = ZooKeeper.new("localhost:2181", :watcher => :default)
    @zk2 = ZooKeeper.new("localhost:2181", :watcher => :default)
    wait_until{ @zk.connected? && @zk2.connected? }
    @queue_name = "_specQueue"
    @consume_queue = @zk.queue(@queue_name)
    @publish_queue = @zk2.queue(@queue_name)
  end

  after(:each) do
    @consume_queue.destroy!
    @zk.close!
    @zk2.close!
    wait_until{ !@zk.connected? && !@zk2.connected? }
  end

  it "should be able to receive a published message" do
    message_received = false
    @consume_queue.subscribe do |title, data|
      data.should == 'mydata'
      message_received = true
    end
    @publish_queue.publish("mydata")
    wait_until {message_received }
    message_received.should be_true
  end

  it "should be able to receive a custom message title" do
    message_title = false
    @consume_queue.subscribe do |title, data|
      title.should == 'title'
      message_title = true
    end
    @publish_queue.publish("data", "title")
    wait_until { message_title }
    message_title.should be_true
  end

  it "should work even after processing a message from before" do
    @publish_queue.publish("data1", "title")
    message_times = 0
    @consume_queue.subscribe do |title, data|
      title.should == "title"
      message_times += 1
    end

    @publish_queue.publish("data2", "title")
    wait_until { message_times == 2 }
    message_times.should == 2

  end



end
