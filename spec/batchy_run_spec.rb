require 'spec_helper'

describe 'Batchy run method' do
  it 'should create a batch to run' do
    Batchy.run(:name => 'test') do | b | 
      b.class.should == Batchy::Batch
    end
  end

  it 'should finish successfully if there are no errors' do
    bch = nil
    Batchy.run(:name => 'test') do | b | 
      bch = b
    end
    bch.state.should == 'success'
  end

  it 'should finish with as errored if there was an error' do
    bch = nil
    Batchy.run(:name => 'test') do | b | 
      bch = b
      raise Exception, "this is an exception"
    end
    bch.state.should == 'errored'
  end

  it 'should finish with as stopped if there was a stoppped error' do
    bch = nil
    Batchy.run(:name => 'test') do | b | 
      bch = b
      raise Batchy::StoppedError, "We need to stop"
    end
    bch.state.should == 'stopped'
  end


  it 'should save the error message in the batch' do
    bch = nil
    Batchy.run(:name => 'test') do | b | 
      bch = b
      raise Exception, "this is an exception"
    end
    bch.error.message =~ /this is an exception/
  end

  it 'should not run the block if ignored' do
    Batchy.configure do | c | 
      c.allow_duplicates = false
    end

    b = FactoryGirl.create(:batch, :guid => 'same')
    b.start!

    called = false
    Batchy.run(:name => 'test', :guid => 'same') do | b | 
      called = true
    end

    called.should be_false
  end

  it 'should fire success callbacks' do
    called = false
    Batchy.run(:name => 'test') do | b |
      b.on_success do
        called = true
      end
    end
    called.should be_true
  end

  it 'should fire error callbacks' do
    called = false
    Batchy.run(:name => 'test') do | b |
      b.on_failure do
        called = true
      end
      raise Exception, "this is an exception"
    end
    called.should be_true
  end

  it 'should fire ensure callbacks' do
    called = false
    Batchy.run(:name => 'test') do | b |
      b.on_ensure do
        called = true
      end
      raise Exception, "this is an exception"
    end
    called.should be_true
  end

  it 'should be able to name the batch' do
    name = nil
    Batchy.run(:name => "this batch") do | b |
      name = b.name
    end

    name.should == "this batch"
  end

  it 'should be able to set the guid on the batch' do
    guid = nil
    Batchy.run(:name => "this batch", :guid => 'this guid') do | b |
      guid = b.guid
    end

    guid.should == "this guid"
  end

  it 'should not raise an error if not failure callbacks are defined' do
    lambda {
    Batchy.run(:name => "this batch") do | b |
      raise StandardError, 'stuff'
    end
    }.should_not raise_error
  end

  it 'should allow multiple callbacks' do
    success1 = false
    success2 = false

    Batchy.run(:name => "this batch") do | b |
      b.on_success do | bch |
        success1 = true
      end
      b.on_success do | bch |
        success2 = true
      end
    end

    success1.should be_true
    success2.should be_true
  end

  it 'should accept a method for callback' do
    called = false
    to_call = lambda { | b |
      called = true
    }

    Batchy.run(:name => 'this batch') do | b |
      b.on_success to_call
    end

    called.should be_true
  end

  it 'should not raise error if no callbacks are given' do
    lambda {
      Batchy.run(:name => 'this batch') do | b |
        # do something
      end
    }.should_not raise_error
  end

  it 'should fire an ensure callback on success' do
    called = false
    Batchy.run(:name => 'this batch') do | b |
      b.on_ensure do | bch |
        called = true
      end
      # do something
    end

    called.should be_true
  end

  it 'should call a success callback on success' do
    called = false
    Batchy.run(:name => 'this batch') do | b |
      b.on_success do | bch |
        called = true
      end
      # do something
    end

    called.should be_true
  end

  it 'should call a failure callback on failure' do
    called = false
    Batchy.run(:name => 'this batch') do | b |
      b.on_failure do | bch |
        called = true
      end

      raise StandardError, "messed up"
    end

    called.should be_true
  end

  it 'should fire an ensure callback on error' do
    called = false
    Batchy.run(:name => 'this batch') do | b |
      b.on_ensure do | bch |
        called = true
      end

      raise StandardError, "messed up"
    end

    called.should be_true
  end

  it 'should serialize the backtrace' do 
    batch_id = nil
    Batchy.run(:name => 'serialize') do | b |
      batch_id = b.id
      raise StandardError, "this is a stick up"
    end

    batch = Batchy::Batch.find(batch_id)
    batch.error.message.should_not be_nil
    batch.error.backtrace.should_not be_nil
    batch.backtrace.should_not be_nil
  end

  it 'should exit with an error even if an error is raised during error handling' do
    batch = nil

    lambda { 
      Batchy.run(:name => "error batch") do | b |
        b.on_failure do 
          raise StandardError, "you're f'd"
        end

        batch = b
        raise StandardError, "first blood"
      end
    }.should raise_error

    batch.reload
    batch.state.should == 'errored'
  end

  it 'should serialize the error on failure' do
    batch = nil
    Batchy.run(:name => 'serialize') do | b |
      batch = b
      raise StandardError, "this is an error"
    end

    batch.reload
    batch.error.class.should == StandardError
  end

  it 'should be possible to reraise the error on failure' do
    lambda {
      Batchy.run(:name => 'reraise error') do | b |
        b.on_failure do
          raise b.error
        end

        raise StandardError, "this is an error"
      end
    }.should raise_error(StandardError)
  end
end
