require 'spec_helper'

describe 'Batchy process handling' do
  before(:each) do
    @batch = Batchy::Batch.create :name => 'this test batch'
  end

  it 'should return the correct pid' do
    ::Process.should_receive(:pid).at_least(1).times.and_return(234)
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

  it 'should be able to check if its process is running' do
    @batch.start!

    @batch.process_running?.should be_true

    Sys::ProcTable.should_receive(:ps).with(@batch.pid).and_return(nil)
    @batch.process_running?.should be_false
  end

  it 'should raise error if the hostname doesnt match when checking' do
    @batch.start!

    ::Socket.should_receive(:gethostname).and_return("example.com")

    lambda { @batch.process_running?.should be_false }.should raise_error(Batchy::Error)
  end

  it 'should finish with errors if the batch in a running state but the process is not available' do
    b1 = Batchy::Batch.create :name => 'this test batch', :guid => 'same'
    b2 = Batchy::Batch.create :name => 'this test batch 2', :guid => 'same'


    b1.start!
    Sys::ProcTable.should_receive(:ps).with(b1.pid).and_return(nil)

    b2.clear_zombies
    
    b1.reload
    b1.state.should == 'errored'
  end

  # pending 'should finish with errors if the batch in a new state but the process is not available [NOT SURE IF WE NEED THIS]'

  describe 'hostname' do
    it 'should not kill a batch unless the hostname matches' do
      ::Socket.should_receive(:gethostname).and_return("example.com")

      @batch.start
      ::Socket.should_receive(:gethostname).twice.and_return('notmatching.com')

      ::Process.should_not_receive(:kill)
      @batch.kill

      ::Process.should_not_receive(:kill)
      @batch.kill!
    end

    it 'should kill a batch if the hostname matches' do
      @batch.start

      ::Process.should_receive(:kill)
      @batch.kill

      ::Process.should_receive(:kill)
      @batch.kill!
    end

    it 'should limit duplicate checking to the current hostname if asked' do
      b1 = Batchy::Batch.create :name => 'this test batch', :guid => 'same'
      b1.start!
      b1.hostname = 'example.com'
      b1.save

      b2 = Batchy::Batch.create :name => 'this test batch 2', :guid => 'same'
      b2.duplicate_batches(:limit_to_current_host => true).should be_blank
    end
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

      Batchy::Batch.should_not_receive(:expired)
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
