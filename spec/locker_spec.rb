require File.join(File.dirname(__FILE__), %w[spec_helper])

describe ZooKeeper::Locker, "with no paths" do

  before(:each) do
    @zk = ZooKeeper.new("localhost:2181")
    @zk2 = ZooKeeper.new("localhost:2181")
    wait_until{ @zk.connected? && @zk2.connected? }
    @path_to_lock = "/lock_tester"
  end

  after(:each) do
    @zk.close
    @zk2.close
    wait_until{ !@zk.connected? && !@zk2.connected? }
  end

  it "should be able to acquire the lock if no one else is locking it" do
    @zk.locker(@path_to_lock).lock!.should be_true
  end

  it "should not be able to acquire the lock if someone else is locking it" do
    @zk.locker(@path_to_lock).lock!.should be_true
    @zk2.locker(@path_to_lock).lock!.should be_false
  end

  it "should be able to acquire the lock after the first one releases it" do
    lock1 = @zk.locker(@path_to_lock)
    lock2 = @zk2.locker(@path_to_lock)
    
    lock1.lock!.should be_true
    lock2.lock!.should be_false
    lock1.unlock!
    lock2.lock!.should be_true
  end

  it "should be able to acquire the lock if the first locker goes away" do
    lock1 = @zk.locker(@path_to_lock)
    lock2 = @zk2.locker(@path_to_lock)

    lock1.lock!.should be_true
    lock2.lock!.should be_false
    @zk.close
    lock2.lock!.should be_true
  end
  


end
