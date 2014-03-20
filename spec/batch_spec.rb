require 'spec_helper'

describe Batchy::Batch do
  before(:each) do
    @batch = FactoryGirl.create(:batch)
  end

  it 'should require a name' do
    @batch = FactoryGirl.build(:batch, :name => nil)
    lambda { @batch.save! }.should raise_error(ActiveRecord::RecordInvalid)
  end

  it 'should start in a "new" state' do
    @batch.state.should == 'new'
  end

  it 'should start running if nothing else is running' do
    @batch.should_receive(:invalid_duplication).and_return(false)
    @batch.start

    @batch.running?.should be_true
  end

  it 'should be ignored if another is running' do
    @batch.should_receive(:invalid_duplication).and_return(true)

    @batch.start
    @batch.ignored?.should be_true
  end

  it 'should still set start and end time on ignore' do
    @batch.should_receive(:invalid_duplication).and_return(true)

    @batch.start
    @batch.started_at.should_not be_nil
    @batch.finished_at.should_not be_nil
  end

  it 'should set pid on start' do
    ::Process.should_receive(:pid).and_return(1234)

    @batch.start
    @batch.pid.should == 1234
  end

  it 'should set hostname on start' do
    ::Socket.should_receive(:gethostname).and_return('example.com')

    @batch.start
    @batch.hostname.should == 'example.com'
  end

  it 'should set hostname if ignored' do
    ::Socket.should_receive(:gethostname).and_return('example.com')
    @batch.should_receive(:invalid_duplication).and_return(true)

    @batch.start
    @batch.hostname.should == 'example.com'
  end

  it 'should still set its pid if ignored' do
    ::Process.should_receive(:pid).and_return(1234)
    @batch.should_receive(:invalid_duplication).and_return(true)

    @batch.start
    @batch.pid.should == 1234
  end

  it 'should finish in error state if there is an error' do
    @batch.start

    @batch.error = StandardError.new("This is an error")
    @batch.finish
    @batch.errored?.should be_true
  end

  it 'should know if it has errors' do
    @batch.has_errors.should be_false

    @batch.error = StandardError.new("This is an error")
    @batch.has_errors.should be_true
  end

  it 'should set started_at time on start' do
    @batch.start!
    @batch.started_at.should_not be_nil

    # Check if the change sticks
    @batch.reload
    @batch.started_at.should_not be_nil
  end

  it 'should set finished_at time on finish' do
    @batch.start
    @batch.finish!
    @batch.finished_at.should_not be_nil

    # Check if the change sticks
    @batch.reload
    @batch.finished_at.should_not be_nil
  end

  it 'should serialize the exception' do
    @batch.start
    @batch.error = StandardError.new("this is an error")
    @batch.finish!

    @batch.reload
    @batch.error.class.should == StandardError
  end

  it 'should only be able to set the backtrace through the error' do
    backtrace = ["/Users/rbriski/dev/batchy/spec/batchy_run_spec.rb:205:in `block (3 levels) in <top (required)>'", "/Users/rbriski/dev/batchy/lib/batchy.rb:98:in `run'"]

    ex = StandardError.new("this is an error")
    ex.set_backtrace backtrace

    @batch.start
    @batch.error = ex
    @batch.finish!

    @batch.reload
    @batch.backtrace.should == backtrace
  end

  it 'should only be able to access the backtrace through the error' do
    backtrace = ["/Users/rbriski/dev/batchy/spec/batchy_run_spec.rb:205:in `block (3 levels) in <top (required)>'", "/Users/rbriski/dev/batchy/lib/batchy.rb:98:in `run'"]

    ex = StandardError.new("this is an error")
    ex.set_backtrace backtrace

    @batch.start
    @batch.error = ex
    @batch.finish!

    @batch.reload
    @batch.error.backtrace.should == backtrace
  end

  it 'should be able to handle a string in the error field' do
    @batch.start
    @batch.error = "This is an error"
    @batch.finish!

    @batch.error.should == "This is an error"
    @batch.error.backtrace.should be_nil
  end

  describe 'parents' do
    it 'should set its parent' do
      child = FactoryGirl.create(:batch)

      child.parent = @batch
      child.save!

      child.reload
      child.parent.should == @batch
      child.parent_id.should == @batch.id
    end

    it 'should set its children' do
      child1 = FactoryGirl.create(:batch)
      child2 = FactoryGirl.create(:batch)

      @batch.children << child1
      @batch.children << child2
      @batch.reload

      @batch.children.should == [child1, child2]
    end

  end

  describe 'guid' do
    before(:each) do
      @g_batch = FactoryGirl.create(:batch_with_guid)
      @g_batch.start!
    end

    it 'should be able to check how many duplicate batches are running' do
      new_batch = FactoryGirl.build(:batch_with_guid)

      new_batch.duplicate_batches.count.should == 1
    end

    it 'should raise an error if duplicate_batches is run on a nil guid' do
      b1 = FactoryGirl.create(:batch, :guid => nil)
      b2 = FactoryGirl.create(:batch, :guid => nil)

      b1.start!
      lambda { b2.duplicate_batches.count }.should raise_error(Batchy::Error)
    end

    it 'should not count a nil guid as a duplicate of another nil guid' do
      b1 = FactoryGirl.create(:batch, :guid => nil)
      b2 = FactoryGirl.create(:batch, :guid => nil)

      b1.start!
      b2.already_running.should be_false
    end

    it 'should tell if another batch is already running' do
      new_batch = FactoryGirl.build(:batch_with_guid)
      new_batch.already_running.should be_true
    
      @g_batch.finish!
      new_batch.already_running.should be_false
    end

    it 'should ignore duplicates if configured' do
      new_batch = FactoryGirl.build(:batch_with_guid)

      Batchy.configure.should_receive(:allow_duplicates).and_return(false)
      new_batch.should_receive(:already_running).and_return(true)

      new_batch.start!
      new_batch.ignored?.should be_true
    end
  end
  
  describe 'blackbox ignore test' do
    it 'should fire ignore and ensure callbacks on ignore' do
      ignored = false
      ensured = false
      Batchy.configure.allow_duplicates = false
      b1 = Batchy::Batch.create :name => 'this test batch', :guid => 'same'
      b1.start!
      b1.stub(:already_running).and_return(true)

      ignore_block = Proc.new{ignored = true}
      ensure_block = Proc.new{ensured = true}
      Batchy.run :name => 'this test batch 2', :guid => 'same', 
      :on_ignore => ignore_block, :on_ensure => ensure_block do |b2| 
        puts "IGNORED" # this line will not be executed
      end
      ignored.should be_true
      Batchy.configure.allow_duplicates = true
    end

    it 'should not execute code inside an ignored batch block' do
      ignored = false

      Batchy.configure.allow_duplicates = false
      b1 = Batchy::Batch.create :name => 'this test batch', :guid => 'same'
      b1.start!

      Batchy.run :name => 'this test batch 2', :guid => 'same' do |b2| 
        ignored = true
      end
      ignored.should be_false
      Batchy.configure.allow_duplicates = true
    end

  end

  describe 'callbacks' do
    it 'should fire an ignore callback on ignore' do
      called = false
      @batch.on_ignore do | bch |
        called = true
      end
      @batch.should_receive(:invalid_duplication).and_return(true)

      @batch.start
      called.should be_true
    end

    it 'should still fire the ensure callbacks on ignore' do
      called = false
      @batch.on_ensure do | bch |
        called = true
      end
      @batch.should_receive(:invalid_duplication).and_return(true)

      @batch.start
      called.should be_true
    end
  end

  it 'should be able to set expiration time' do
    day_hence = DateTime.now + 1.day

    @batch.expire_at = day_hence
    @batch.start!

    @batch.expire_at.should == day_hence
  end

  it 'should know if its expired' do
    @batch.expire_at = DateTime.now - 1.day
    @batch.start!

    @batch.expired?.should be_true
  end
end


