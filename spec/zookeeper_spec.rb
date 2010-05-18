require File.join(File.dirname(__FILE__), %w[spec_helper])

describe ZooKeeper, "with no paths" do

  before(:each) do
    @zk = ZooKeeper.new("localhost:2181", :watcher => SilentWatcher.new)
    wait_until{ @zk.connected? }
    delete_test!
  end
  
  after(:each) do
    delete_test!
    @zk.close
    wait_until{ @zk.closed? }
  end

  def delete_test!
    if (@zk.exists?('/test'))
      @zk.children("/test").each do |child|
        @zk.delete("/test/#{child}")
      end
      @zk.delete('/test')
    end
  end



  it "should not exist" do
    @zk.exists?("/test").should be_nil
  end

  it "should create a path" do
    @zk.create("/test", "test_data").should == "/test"
  end

  it "should be able to set the data" do
    @zk.create("/test", "something")
    @zk.set("/test", "somethingelse")
    @zk.get("/test").first.should == "somethingelse"
  end

  it "should raise an exception for a non existent path" do
    lambda { @zk.get("/non_existent_path") }.should raise_error(KeeperException::NoNode)
  end

  it "should create a path with sequence set" do
    @zk.create("/test", "test_data", :mode => :persistent_sequential).should =~ /test(\d+)/
  end

  it "should create an ephemeral path" do
    @zk.create("/test", "test_data", :mode => :ephemeral).should == "/test"
  end

  it "should remove ephemeral path when client session ends" do
    @zk.create("/test", "test_data", :mode => :ephemeral).should == "/test"
    @zk.exists?("/test").should_not be_nil
    @zk.close

    @zk = ZooKeeper.new("localhost:2181", :watcher => SilentWatcher.new)
    wait_until{ @zk.connected? }    
    @zk.exists?("/test").should be_nil
  end

  it "should remove sequential ephemeral path when client session ends" do
    created = @zk.create("/test", "test_data", :mode => :ephemeral_sequential)
    created.should =~ /test(\d+)/
    @zk.exists?(created).should_not be_nil
    @zk.close

    @zk = ZooKeeper.new("localhost:2181", :watcher => SilentWatcher.new)
    wait_until{ @zk.connected? }        
    @zk.exists?(created).should be_nil
  end

#  it "should asynchronously create a path and execute callback on callback object" do
#    pending('Not implemented in MRI version yet') unless defined?(JRUBY_VERSION)
#    callback = MockStringCallback.new
#    context = Time.new
#    @zk.create("/test", "test_data", :callback => callback, :context => context)
#    wait_until { callback.process_result_completed? }
#    callback.return_code.should == 0
#    callback.path.should        == "/test"
#    callback.context.should     == context
#    callback.name.should        == "/test"
#  end

end

describe ZooKeeper, "with a path" do

  before(:each) do
    @zk = ZooKeeper.new("localhost:2181", :watcher => SilentWatcher.new)
    wait_until{ @zk.connected? }
    delete_test!
    @zk.create("/test", "test_data", :mode => :persistent)
  end

  after(:each) do
    delete_test!
    @zk.close
    wait_until{ @zk.closed? }
  end

  def delete_test!
    if (@zk.exists?('/test'))
      @zk.children("/test").each do |child|
        @zk.delete("/test/#{child}")
      end
      @zk.delete('/test')
    end
  end

  it "should return a stat" do
    @zk.exists?("/test").should be_instance_of(ZooKeeper::Stat)
  end

  it "should get data and stat" do
    data, stat = @zk.get("/test", :stat => stat)
    data.should == "test_data"
    stat.should be_a_kind_of(ZooKeeper::Stat)
    stat.created_time.should_not == 0
  end

  it "should set data with a file" do
    file = File.read('spec/test_file.txt')
    @zk.set("/test", file)
    @zk.get("/test").first.should == file
  end

  it "should delete path" do
    @zk.delete("/test")
    @zk.exists?("/test").should be_nil
  end

  it "should create a child path" do
    @zk.create("/test/child", "child").should == "/test/child"
  end

  it "should create sequential child paths" do
    (child1 = @zk.create("/test/child", "child1", :mode => :persistent_sequential)).should =~ /\/test\/child(\d+)/
    (child2 = @zk.create("/test/child", "child2", :mode => :persistent_sequential)).should =~ /\/test\/child(\d+)/
    children = @zk.children("/test")
    children.length.should == 2
    children.should be_include(child1.match(/\/test\/(child\d+)/)[1])
    children.should be_include(child2.match(/\/test\/(child\d+)/)[1])    
  end

  it "should have no children" do
    @zk.children("/test").should be_empty
  end

#  it "should asynchronously delete a path and execute callback" do
#    pending('Not implemented in MRI version yet') unless defined?(JRUBY_VERSION)
#    callback = MockVoidCallback.new
#    context = Time.new
#    @zk.delete("/test", :callback => callback, :context => context)
#    wait_until { callback.process_result_completed? }
#    callback.return_code.should == 0
#    callback.path.should        == "/test"
#    callback.context.should     == context
#  end
#
#  it "should asynchronously do an exists and execute callback" do
#    pending('Not implemented in MRI version yet') unless defined?(JRUBY_VERSION)
#    callback = MockStatCallback.new
#    context = Time.new
#    @zk.exists("/test", :callback => callback, :context => context)
#    wait_until { callback.process_result_completed? }
#    callback.return_code.should == 0
#    callback.path.should        == "/test"
#    callback.context.should     == context
#    callback.stat.should be_a_kind_of(ZooKeeper::Stat)
#  end
#
#  it "should asynchronously set data and execute callback" do
#    pending('Not implemented in MRI version yet') unless defined?(JRUBY_VERSION)
#    callback = MockStatCallback.new
#    context = Time.new
#    @zk.set("/test", "foo", :callback => callback, :context => context)
#    @zk.get("/test").first.should == "foo"
#    wait_until { callback.process_result_completed? }
#    callback.return_code.should == 0
#    callback.path.should        == "/test"
#    callback.context.should     == context
#    callback.stat.should be_a_kind_of(ZooKeeper::Stat)
#  end
#
#  it "should asynchronously get data and execute callback" do
#    pending('Not implemented in MRI version yet') unless defined?(JRUBY_VERSION)
#    callback = MockDataCallback.new
#    context = Time.new
#    @zk.get("/test", :callback => callback, :context => context).should be_nil
#    wait_until { callback.process_result_completed? }
#    callback.return_code.should == 0
#    callback.path.should        == "/test"
#    callback.context.should     == context
#    callback.data.should == "test_data"
#    callback.stat.should be_a_kind_of(ZooKeeper::Stat)
#  end

end

describe ZooKeeper, "with children" do

  before(:each) do
    @zk = ZooKeeper.new("localhost:2181", :watcher => SilentWatcher.new)
    wait_until{ @zk.connected? }
    delete_test!
    @zk.create("/test", "test_data", :mode => :persistent)
    @zk.create("/test/child", "child", :mode => "persistent").should == "/test/child"
  end

  after(:each) do
    delete_test!
    @zk.close
    wait_until{ @zk.closed? }
  end

  def delete_test!
    if (@zk.exists?('/test'))
      @zk.children("/test").each do |child|
        @zk.delete("/test/#{child}")
      end
      @zk.delete('/test')
    end
  end

  it "should get children" do
    @zk.children("/test").should eql(["child"])
  end

#  it "should asynchronously get children and execute callback" do
#    pending('Not implemented in MRI version yet') unless defined?(JRUBY_VERSION)
#    callback = MockChildrenCallback.new
#    context = Time.new
#    @zk.children("/test", :callback => callback, :context => context).should be_nil
#    wait_until { callback.process_result_completed? }
#    callback.return_code.should == 0
#    callback.path.should        == "/test"
#    callback.context.should     == context
#    callback.children.should eql(["child"])
#  end

end
#
#describe ZooKeeper, "asynchronous create with no paths" do
#
#  before(:each) do
#    @zk = ZooKeeper.new("localhost:2181", :watcher => SilentWatcher.new)
#    wait_until{ @zk.connected? }
#    @completed  = false
#  end
#
#  after(:each) do
#    @zk.close
#    wait_until{ @zk.closed? }
#  end
#
#  def completed?
#    return @completed
#  end
#
#  def process_result(return_code, path, context, name)
#    @return_code, @path, @context, @name = return_code, path, context, name
#    @completed = true
#  end
#
#  it "should create a path and execute callback on self" do
#    pending('Not implemented in MRI version yet') unless defined?(JRUBY_VERSION)
#    context = Time.new
#    @zk.create("/test", "test_data", :callback => self, :context => context)
#    wait_until { completed? }
#    @return_code.should == 0
#    @path.should        == "/test"
#    @context.should     == context
#    @name.should        == "/test"
#  end
#
#  it "should asynchronously create a path and execute callback on proc" do
#    pending('Not implemented in MRI version yet') unless defined?(JRUBY_VERSION)
#    callback = proc do |return_code, path, context, name|
#      self.instance_variable_set("@return_code", return_code)
#      self.instance_variable_set("@path", path)
#      self.instance_variable_set("@context", context)
#      self.instance_variable_set("@name", name)
#      self.instance_variable_set("@completed", true)
#    end
#
#    context = Time.new
#    @zk.create("/test", "test_data", :callback => callback, :context => context)
#    wait_until { completed? }
#    @return_code.should == 0
#    @path.should        == "/test"
#    @context.should     == context
#    @name.should        == "/test"
#  end
#
#end

#describe ZooKeeper, "watches" do
#
#  before(:each) do
#    @watcher = EventWatcher.new
#    @zk1 = ZooKeeper.new("localhost:2181", :watcher => @watcher)
#    @zk2 = ZooKeeper.new("localhost:2181", :watcher => SilentWatcher.new)
#    wait_until{ @zk1.connected? && @zk2.connected? }
#    delete_test!
#    @zk1.create("/test", "test_data", :mode => :persistent)
#  end
#
#  after(:each) do
#    @zk1.close
#    @zk2.close
#    delete_test!
#    wait_until{ @zk1.closed? && @zk2.closed? }
#  end
#
#  def do_cool!
#    if (@zk1.exists?('/test'))
#      @zk1.children("/test").each do |child|
#        @zk1.delete("/test/#{child}")
#      end
#      @zk1.delete('/test')
#    end
#    @zk1.delete("/fred") if @zk1.exists?("/fred")
#  end

#  it "should get data changed event" do
#    @zk1.get("/test", :watch => true)
#    @zk2.set("/test", "foo")
#    wait_until { @watcher.received_disconnected }
#    @watcher.event_types.should include(ZooKeeper::WatcherEvent::EventNodeDataChanged)
#  end
#
#  it "should get an event when a path is created" do
#    @zk1.exists?("/fred", :watch => true)
#    @zk2.create("/fred", "freds_data").should == "/fred"
#    #wait_until { @watcher.received_disconnected }
#    @watcher.event_types.should include(ZooKeeper::WatcherEvent::EventNodeCreated)
#  end
##
##  it "should get an event when a path is deleted" do
##    @zk1.exists?("/test", :watch => true)
##    @zk2.delete("/test")
##    #wait_until { @watcher.received_disconnected }
##    @watcher.event_types.should include(ZooKeeper::WatcherEvent::EventNodeDeleted)
##  end
##
##  it "should get an event when a child is added" do
##    @zk1.children("/test", :watch => true)
##    @zk2.create("/test/child", "child1", :mode => :ephemeral_sequential).should == "/test/child0"
##    #wait_until { @watcher.received_disconnected }
##    @watcher.event_types.should include(ZooKeeper::WatcherEvent::EventNodeChildrenChanged)
##  end
#
#end
#
#describe ZooKeeper, "versioning data" do
#
#  before(:each) do
#    @zk = ZooKeeper.new("localhost:2181", :watcher => SilentWatcher.new)
#    wait_until{ @zk.connected? }
#    @zk.create("/test", "test_data")
#  end
#
#  after(:each) do
#    @zk.close
#    wait_until{ @zk.closed? }
#  end
#
#  it "should allow setting data with a version" do
#    @zk.set("/test", "test_data_1", :version => 0)
#    @zk.get("/test", :version => 0).first.should == "test_data_1"
#  end
#
#  it "should increment version when setting data" do
#    @zk.set("/test", "test_data_1")
#    @zk.get("/test", :version => 1).first.should == "test_data_1"
#  end
#
#  it "should delete path with a version" do
#    @zk.delete("/test", :version => 0)
#    @zk.exists?("/test").should be_nil
#  end
#
#end
#
#describe ZooKeeper, "stats" do
#
#  before(:each) do
#    @zk = ZooKeeper.new("localhost:2181", :watcher => SilentWatcher.new)
#    wait_until{ @zk.connected? }
#    @zk.create("/test", "test_data")
#    @zk.set("/test", "test_data_1")
#  end
#
#  after(:each) do
#    @zk.close
#    wait_until{ @zk.closed? }
#  end
#
#  it "should return stat with exists?" do
#    stat = @zk.exists?("/test")
#    stat.should_not be_nil
#    stat.should be_a_kind_of(ZooKeeper::Stat)
#
#    stat.created_zxid.should       == 2
#    stat.last_modified_zxid.should == 3
#
#    stat.created_time.should        > 0
#    stat.last_modified_time.should  > 0
#    stat.last_modified_time.should  > stat.created_time
#
#    stat.version.should            == 1
#    stat.child_list_version.should == 0
#    stat.acl_list_version.should   == 0
#    stat.ephemeral_owner.should    == 0
#  end
#
#end
#
#describe ZooKeeper, "ACL" do
#
#  before(:each) do
#    @zk1 = ZooKeeper.new("localhost:2181", :watcher => SilentWatcher.new)
#    @zk2 = ZooKeeper.new("localhost:2181", :watcher => SilentWatcher.new)
#    wait_until{ @zk1.connected? && @zk2.connected? }
#  end
#
#  after(:each) do
#    @zk1.close
#    @zk2.close
#    wait_until{ @zk1.closed? && @zk2.closed? }
#  end
#
#  it "should create a path with OPEN_ACL_UNSAFE permissions by default" do
#    pending('Not implemented in MRI version yet') unless defined?(JRUBY_VERSION)
#    @zk1.create("/test", "test_data")
#    @zk1.acls("/test").first.should == ZooKeeper::ACL::OPEN_ACL_UNSAFE
#  end
#
#  it "should create a path with READ_ACL_UNSAFE permissions" do
#    pending('Not implemented in MRI version yet') unless defined?(JRUBY_VERSION)
#    @zk1.create("/test", "test_data", :acl => ZooKeeper::ACL::READ_ACL_UNSAFE)
#    @zk1.acls("/test").first.should == ZooKeeper::ACL::READ_ACL_UNSAFE
#  end
#
#  it "should get acl info asynchronously" do
#    pending('Not implemented in MRI version yet') unless defined?(JRUBY_VERSION)
#    callback = MockAclCallback.new
#    context = Time.new
#    @zk1.create("/test", "test_data")
#    @zk1.acls("/test", :callback => callback, :context => context)
#    wait_until { callback.process_result_completed? }
#    callback.return_code.should == 0
#    callback.path.should        == "/test"
#    callback.context.should     == context
#    callback.acl.should         == ZooKeeper::ACL::OPEN_ACL_UNSAFE
#  end
#
#  it "should create a path with CREATOR_ALL_ACL permissions" do
#    pending('Not implemented in MRI version yet') unless defined?(JRUBY_VERSION)
#    @zk1.add_auth_info(:scheme => "digest", :auth => "shane:password")
#    @zk1.create("/test", "test_data", :acl => ZooKeeper::ACL::CREATOR_ALL_ACL)
#    @zk1.acls("/test").first.should == [ZooKeeper::ACL.new(ZooKeeper::Permission::ALL | ZooKeeper::Permission::ADMIN,
#                                        ZooKeeper::Id.new('digest', 'shane:pgPxAF2N8U79uqcuGPQx3C6J2c8='))]
#  end
#
#  it "should set creator to read with CREATOR_ALL_ACL permissions" do
#    pending('Not implemented in MRI version yet') unless defined?(JRUBY_VERSION)
#    @zk1.add_auth_info(:scheme => "digest", :auth => "shane:password")
#    @zk1.create("/test", "test_data", :acl => ZooKeeper::ACL::CREATOR_ALL_ACL)
#    @zk2.add_auth_info(:scheme => "digest", :auth => "shane:password")
#    @zk2.get("/test").first.should == "test_data"
#  end
#
#  it "should create node with CREATOR_ALL_ACL permissions if no authentcated ids present" do
#    pending('Not implemented in MRI version yet') unless defined?(JRUBY_VERSION)
#    lambda { @zk1.create("/test", "test_data", :acl => ZooKeeper::ACL::CREATOR_ALL_ACL) }.should raise_error(KeeperException::InvalidACL)
#  end
#
#  it "should not allow world to read node with CREATOR_ALL_ACL permissions" do
#    pending('Not implemented in MRI version yet') unless defined?(JRUBY_VERSION)
#    @zk1.add_auth_info(:scheme => "digest", :auth => "shane:password")
#    @zk1.create("/test", "test_data", :acl => ZooKeeper::ACL::CREATOR_ALL_ACL)
#    lambda { @zk2.get("/test") }.should raise_error(KeeperException::NoAuth)
#  end
#
#  it "should allow world to read with READ_ACL_UNSAFE permissions" do
#    pending('Not implemented in MRI version yet') unless defined?(JRUBY_VERSION)
#    @zk1.create("/test", "test_data", :acl => ZooKeeper::ACL::READ_ACL_UNSAFE)
#    @zk2.get("/test").first.should == "test_data"
#  end
#
#  it "should not allow world to write with READ_ACL_UNSAFE permissions" do
#    pending('Not implemented in MRI version yet') unless defined?(JRUBY_VERSION)
#    @zk1.create("/test", "test_data", :acl => ZooKeeper::ACL::READ_ACL_UNSAFE)
#    lambda { @zk2.set("/test", "new_data") }.should raise_error(KeeperException::NoAuth)
#  end
#
#  it "should accept new ACL" do
#    pending('Not implemented in MRI version yet') unless defined?(JRUBY_VERSION)
#    @zk1.create("/test", "test_data")
#    lambda { @zk1.set_acl("/test", :acl =>  ZooKeeper::ACL::OPEN_ACL_UNSAFE) }.should_not raise_error(KeeperException::InvalidACL)
#  end
#
#end
