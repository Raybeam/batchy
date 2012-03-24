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
    @batch.should_receive(:multiples_allowed).and_return(false)
    @batch.should_receive(:already_running).and_return(false)
    @batch.start

    @batch.running?.should be_true
  end

  it 'should be ignored if another is running' do
    @batch.should_receive(:multiples_allowed).and_return(false)
    @batch.should_receive(:already_running).and_return(true)

    @batch.start
    @batch.ignored?.should be_true
  end

  it 'should finish in error state if there is an error' do
    @batch.start

    @batch.error = "This is an error"
    @batch.finish
    @batch.errored?.should be_true
  end

  it 'should know if it has errors' do
    @batch.has_errors.should be_false

    @batch.error = 'here is an error'
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

  describe 'guid' do
    before(:each) do
      @g_batch = FactoryGirl.create(:batch_with_guid)
      @g_batch.start!
    end

    it 'should be able to check how many duplicate batches are running' do
      new_batch = FactoryGirl.build(:batch_with_guid)

      new_batch.duplicate_batches.count.should == 1
    end

    it 'should tell if another batch is already running' do
      new_batch = FactoryGirl.build(:batch_with_guid)
      new_batch.already_running.should be_true
    
      @g_batch.finish!
      new_batch.already_running.should be_false
    end
  end

  describe 'callbacks' do
    it 'should call a success callback on success' do
      success = false
      @batch.on_success do | bch |
        success = true
      end

      @batch.start
      @batch.finish
      success.should be_true
    end

    it 'should call a failure callback on failure' do
      failed = false
      @batch.on_failure do | bch |
        failed = true
      end

      @batch.start
      @batch.error = 'This is an error'
      @batch.finish
      failed.should be_true
    end

    it 'should fire an ensure callback on error' do
      called = false
      @batch.on_ensure do | bch |
        called = true
      end

      @batch.start
      @batch.error = 'This is an error'
      @batch.finish
      called.should be_true
    end

    it 'should fire an ensure callback on success' do
      called = false
      @batch.on_ensure do | bch |
        called = true
      end

      @batch.start
      @batch.finish
      called.should be_true
    end

    it 'should allow multiple callbacks' do
      success1 = false
      success2 = false

      @batch.on_success do | bch |
        success1 = true
      end
      @batch.on_success do | bch |
        success2 = true
      end

      @batch.start
      @batch.finish
      success1.should be_true
      success2.should be_true
    end

    it 'should accept a method for callback' do
      called = false
      to_call = lambda { | b |
        called = true
      }

      @batch.on_success to_call
      @batch.start
      @batch.finish

      called.should be_true
    end

    it 'should not raise error if no callbacks are given' do
      @batch.start

      lambda { @batch.finish! }.should_not raise_error
    end

    it 'should not raise error if no error callbacks are given' do
      @batch.start!

      @batch.error = 'messed up'
      lambda { @batch.finish! }.should_not raise_error
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


