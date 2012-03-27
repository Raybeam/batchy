require 'spec_helper'

describe 'Batchy process handling' do
  before(:each) do
    @batch = Batchy::Batch.create :name => 'this test batch'
  end

  it 'should return the correct pid' do
    ::Process.should_receive(:pid).once.and_return(234)
    @batch.start!

    @batch.pid.should == 234
  end

  it 'should be able to kill (SIGTERM) its process' do
    @batch.start!
    ::Process.should_receive(:kill).with('TERM', @batch.pid)

    @batch.kill
  end

  it 'should be able to kill (SIGKILL) its process' do
    @batch.start!
    ::Process.should_receive(:kill).with('KILL', @batch.pid)

    @batch.kill!
  end

  it 'should name the process after itself' do
    $0 = 'previous name'
    Batchy.run(:name => 'this name') do
      $0.should == 'this name'
    end
  end

  it 'should remove its name from the process after completion' do
    $0 = 'previous name'
    Batchy.run(:name => 'this name') do
      # do nothing
    end
    $0.should == 'previous name'
  end

  it 'should return to the previous process name even during failure' do
    $0 = 'previous name'
    Batchy.run(:name => 'this name') do
      raise StandardError, 'oops'
    end
    $0.should == 'previous name'
  end

  describe 'expiration' do
    before(:each) do
      @b_normal = FactoryGirl.create(:batch, :expire_at => (DateTime.now + 1.day))
      @b_expired = FactoryGirl.create(:batch, :expire_at => (DateTime.now - 1.day))
      @b_stopped = FactoryGirl.create(:batch, :expire_at => (DateTime.now - 1.day))

      @b_normal.start!
      @b_expired.start!
    end

    it 'should return expired batches' do
      @b_stopped.start!

      expired_batches = Batchy::Batch.expired
      expired_batches.count.should == 2
    end

    it 'should only return running batch in expired' do
      expired_batches = Batchy::Batch.expired
      expired_batches.count.should == 1
    end

    it 'should kill expired batches (SIGTERM)' do
      Batchy::Batch.should_receive(:expired).and_return([@b_normal, @b_expired])
      @b_normal.should_receive(:kill)
      @b_expired.should_receive(:kill)

      Batchy.clean_expired
    end

    it 'should not issue a mass SIGKILL if disallowed' do
      Batchy.configure do | c |
        c.allow_mass_sigkill = false
      end

      Batchy::Batch.should_not_receive(:expired).and_return([@b_normal, @b_expired])
      Batchy.clean_expired!
    end

    it 'should warn that mass SIGKILL is not allowed' do
      Kernel.should_receive(:warn).once
      Batchy.configure do | c |
        c.allow_mass_sigkill = false
      end

      Batchy.clean_expired!
    end

    it 'should kill expired batches (SIGKILL)' do
      Batchy.configure do | c |
        c.allow_mass_sigkill = true
      end

      Batchy::Batch.should_receive(:expired).and_return([@b_normal, @b_expired])
      @b_normal.should_receive(:kill!)
      @b_expired.should_receive(:kill!)

      Batchy.clean_expired!
    end
  end

end