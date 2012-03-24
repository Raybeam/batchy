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

  it 'should be able to set allow_duplicates to false' do
    Batchy.configure do | c |
      c.allow_duplicates = false
    end

    Batchy.configure.allow_duplicates.should be_false
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

  it 'should call global ignore and ensure callbacks on ignore' do
    b = FactoryGirl.create(:batch, :guid => 'same guid')
    b.start!

    ignore_called = false
    ensure_called = false
    Batchy.configure do | c |
      c.allow_duplicates = false
      c.add_global_ignore_callback do 
        ignore_called = true
      end
      c.add_global_ensure_callback do 
        ensure_called = true
      end
    end

    Batchy.run(:name => 'test', :guid => 'same guid') do | b | 
      stuff = 'happened'
    end
    ignore_called.should be_true
    ensure_called.should be_true
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
