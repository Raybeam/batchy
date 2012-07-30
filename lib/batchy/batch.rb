module Batchy
  class Batch < ActiveRecord::Base
    extend StateMachine::MacroMethods

    self.table_name = 'batchy_batches'

    attr_reader :failure_callbacks
    attr_reader :success_callbacks
    attr_reader :ensure_callbacks
    attr_reader :ignore_callbacks

    validates_presence_of :name
    belongs_to :parent, :class_name => 'Batchy::Batch', :primary_key => :id, :foreign_key => :parent_id
    has_many :children, :primary_key => :id, :foreign_key => :parent_id, :class_name => 'Batchy::Batch'

    serialize :error
    serialize :backtrace

    state_machine :state, :initial => :new do
      event :start do
        transition :new => :ignored, :if => :invalid_duplication
        transition :new => :running
      end
      after_transition :new => :running do | batch, transition |
        batch.started_at = DateTime.now
        batch.pid = Process.pid
        batch.hostname = Socket.gethostname
        batch.save!
      end
      
      # Ignored
      after_transition :new => :ignored do | batch, transition |
        batch.started_at = DateTime.now
        batch.finished_at = DateTime.now
        batch.hostname = Socket.gethostname
        batch.pid = Process.pid
        batch.save!
      end
      after_transition :new => :ignored, :do => :run_ignore_callbacks
      after_transition :new => :ignored, :do => :run_ensure_callbacks

      event :finish do
        transition :running => :success, :unless => :has_errors
        transition :running => :errored
      end
      after_transition :running => [:success, :errored] do | batch, transition |
        batch.finished_at = DateTime.now
        batch.save!
      end
    end

    class << self
      # Return all expired batches that are still running
      def expired
        where('expire_at < ? and state = ?', DateTime.now, 'running')
      end
    end

    # Set up callback queues and states
    def initialize *args
      create_callback_queues
      super
    end

    # Is there batch with the same guid already running?
    def already_running
      return false if guid.nil?

      duplicate_batches.count > 0
    end

    # Removes duplicate batches that are stuck in
    # a running state
    def clear_zombies
      duplicate_batches(:limit_to_current_host => true).each do | dup |
        if not dup.process_running?
          dup.error = Batchy::Error.new("Process has died, moving to a finished state")
          dup.finish!
        end
      end
    end

    # Find all batches with the same guid that are
    # running.
    #
    # limit_to_current_host
    #   This option limit duplicate batches to the
    #   current host.
    #   Default: false
    #
    def duplicate_batches *args
      options = args.extract_options!
      options.reverse_merge! :limit_to_current_host => false

      raise Batchy::Error, "Can not check for duplicate batches on nil guid" if guid.nil?
      rel = self.class.where(:guid => guid, :state => "running")

      if options[:limit_to_current_host]
        rel = rel.where(:hostname => Socket.gethostname)
      end
      return rel if new_record?

      rel.where("id <> ?", id)
    end

    # When serializing an exception, the YAML library does not save the
    # backtrace.  To fix this, we're saving both the error and backtrace
    # when the error is saved
    def error=(err)
      write_attribute(:error, err)
      write_attribute(:backtrace, err.backtrace) if err.respond_to?(:backtrace)
    end

    # Conversely, the backtrace is added to the error after a read
    def error
      err = read_attribute(:error)
      return err if err.blank?

      backtrace = read_attribute(:backtrace)
      if err.respond_to?(:set_backtrace)
        err.set_backtrace(backtrace) 
      else
        def err.backtrace
          nil
        end
      end

      err
    end

    # Is this batch expired
    def expired?
      expire_at < DateTime.now && state == 'running'
    end

    # Does this batch have errors?
    def has_errors
      error?
    end

    # Is this an unwanted duplicate process?
    def invalid_duplication
      !Batchy.configure.allow_duplicates && already_running
    end

    # Issues a SIGTERM to the process running this batch
    def kill
      return false unless hostname == ::Socket.gethostname

      Process.kill('TERM', pid)
    end

    # Issue a SIGKILL to the process running this batch
    # BE CAREFUL! This will kill your application or
    # server if this batch has the same PID.
    def kill!
      return false unless hostname == ::Socket.gethostname
      
      Process.kill('KILL', pid)
    end

    # Adds a callback that runs no matter what the
    # exit state of the batchy block
    def on_ensure *args, &block
      if block_given?
        @ensure_callbacks << block
      else
        @ensure_callbacks << args.shift
      end
    end

    # Add a callback to run on failure of the 
    # batch
    def on_failure *args, &block
      if block_given?
        @failure_callbacks << block
      else
        @failure_callbacks << args.shift
      end
    end

    # Adds a callback that runs if the
    # process is a duplicate
    def on_ignore *args, &block
      if block_given?
        @ignore_callbacks << block
      else
        @ignore_callbacks << args.shift
      end
    end

    # Add a callback to run on successful
    # completion of the batch
    def on_success *args, &block
      if block_given?
        @success_callbacks << block
      else
        @success_callbacks << args.shift
      end
    end

    # Checks to see if the process attached to this
    # batch is active
    def process_running?
      raise Batchy::Error, 'Current host does not match the host running the batch' unless Socket.gethostname == hostname

      not Sys::ProcTable.ps(pid).blank?
    end

    # :nodoc:
    def run_ensure_callbacks
      Batchy.configure.global_ensure_callbacks.each do | ec |
        ec.call(self)
      end
      ensure_callbacks.each do | ec |
        ec.call(self)
      end
    end

    # :nodoc:
    def run_ignore_callbacks
      Batchy.configure.global_ignore_callbacks.each do | ic |
        ic.call(self)
      end
      ignore_callbacks.each do | ic |
        ic.call(self)
      end
    end

    # :nodoc:
    def run_success_callbacks
      Batchy.configure.global_success_callbacks.each do | sc |
        sc.call(self)
      end
      success_callbacks.each do | sc |
        sc.call(self)
      end
    end

    # :nodoc:
    def run_failure_callbacks
      Batchy.configure.global_failure_callbacks.each do | fc |
        fc.call(self)
      end
      failure_callbacks.each do | fc |
        fc.call(self)
      end
    end

    private

    # :nodoc:
    def create_callback_queues
      @success_callbacks = []
      @failure_callbacks = []
      @ensure_callbacks = []
      @ignore_callbacks = []
    end
  end
end
