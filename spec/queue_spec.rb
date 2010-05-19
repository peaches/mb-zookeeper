require File.join(File.dirname(__FILE__), %w[spec_helper])

describe ZooKeeper::Queue do

  before(:each) do
    @zk = ZooKeeper.new("localhost:2181")
    @zk2 = ZooKeeper.new("localhost:2181")
    wait_until{ @zk.connected? && @zk2.connected? }
    @queue_name = "_specQueue"
    @consume_queue = @zk.queue(@queue_name)
    @publish_queue = @zk2.queue(@queue_name)
  end

  after(:each) do
    @consume_queue.destroy!
    @zk.close
    @zk2.close
    wait_until{ !@zk.connected? && !@zk2.connected? }
  end

  it "should be able to receive a published message" do
    message_received = false
    @consume_queue.subscribe do |title, data|
      message_received = data
    end
    @publish_queue.publish("mydata")
    wait_until {message_received == 'mydata'}
    message_received.should == "mydata"
  end

  it "should be able to receive a custom message title" do
    message_title = false
    @consume_queue.subscribe do |title, data|
      message_title = title
    end
    @publish_queue.publish("data", "title")
    wait_until {message_title == 'title'}
    message_title.should == "title"
  end



end
