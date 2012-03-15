require 'spec_helper.rb'

describe 'Batch class' do
  it 'should create a batch to run' do
    Batchy::Batch.run do | b | 
      b.class.should == Batchy::Batch
    end
  end

  it 'should finish successfully if there are no errors' do
    bch = nil
    Batchy::Batch.run do | b | 
      bch = b
    end
    bch.state.should == 'success'
  end

  it 'should finish with as errored if there was an error' do
    bch = nil
    Batchy::Batch.run do | b | 
      bch = b
      raise Exception, "this is an exception"
    end
    bch.state.should == 'errored'
  end

  it 'should save the error message in the batch' do
    bch = nil
    Batchy::Batch.run do | b | 
      bch = b
      raise Exception, "this is an exception"
    end
    bch.error.should =~ /this is an exception/
  end

  it 'should fire success callbacks' do
    called = false
    Batchy::Batch.run do | b |
      b.on_success do
        called = true
      end
    end
    called.should be_true
  end

  it 'should fire error callbacks' do
    called = false
    Batchy::Batch.run do | b |
      b.on_failure do
        called = true
      end
      raise Exception, "this is an exception"
    end
    called.should be_true
  end

  it 'should fire ensure callbacks' do
    called = false
    Batchy::Batch.run do | b |
      b.on_ensure do
        called = true
      end
      raise Exception, "this is an exception"
    end
    called.should be_true
  end
end