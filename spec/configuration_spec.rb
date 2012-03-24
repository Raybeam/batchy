require 'spec_helper'

describe Batchy::Configuration do
  before(:each) do
    Batchy.clear_configuration
  end

  it 'should call global success callbacks on success' do
    called = false
    Batchy.configure do | c |
      c.add_global_success_callback do 
        called = true
      end
    end

    Batchy.run(:name => 'test') do | b | 
      something = nil
    end
    called.should be_true
  end

  it 'should call global failure callbacks on failure' do
    called = false
    Batchy.configure do | c |
      c.add_global_failure_callback do 
        called = true
      end
    end

    Batchy.run(:name => 'test') do | b | 
      raise Exception, "something happened"
    end
    called.should be_true
  end

  it 'should call global ensure callbacks on ensure' do
    called = false
    Batchy.configure do | c |
      c.add_global_ensure_callback do 
        called = true
      end
    end

    Batchy.run(:name => 'test') do | b | 
      raise Exception, "something happened"
    end
    called.should be_true

    called = false
    Batchy.run(:name => 'test') do | b | 
      something = nil
    end
    called.should be_true
  end
end
