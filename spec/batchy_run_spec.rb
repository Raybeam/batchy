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

  it 'should save the error message in the batch' do
    bch = nil
    Batchy.run(:name => 'test') do | b | 
      bch = b
      raise Exception, "this is an exception"
    end
    bch.error.should =~ /this is an exception/
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

  it 'should not raise an error if not failure callbacks are defined' do
    lambda {
    Batchy.run(:name => "this batch") do | b |
      raise StandardError, 'stuff'
    end
    }.should_not raise_error
  end
end