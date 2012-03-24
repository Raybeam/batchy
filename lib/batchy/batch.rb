module Batchy
  class Batch < ActiveRecord::Base
    extend StateMachine::MacroMethods

    self.table_name = 'batchy_batches'

    attr_reader :failure_callbacks
    attr_reader :success_callbacks
    attr_reader :ensure_callbacks

    validates_presence_of :name

    state_machine :state, :initial => :new do
      event :start do
        transition :new => :running, :if => :multiples_allowed
        transition :new => :running, :unless => :already_running
        transition :new => :ignored
      end
      after_transition :new => :running do | batch, transition |
        batch.started_at = DateTime.now
        batch.pid = Process.pid
        batch.save!

        $0 = batch.name if Batchy.configure.name_process
      end

      event :finish do
        transition :running => :success, :unless => :has_errors
        transition :running => :errored
      end
      after_transition :running => [:success, :errored] do | batch, transition |
        batch.finished_at = DateTime.now
        batch.save!
      end
      after_transition :running => :success, :do => :run_success_callbacks
      after_transition :running => :errored, :do => :run_failure_callbacks
      after_transition :running => [:success, :errored], :do => :run_ensure_callbacks
    end

    class << self
      def expired
        where('expire_at < ? and state = ?', DateTime.now, 'running')
      end
    end

    def initialize *args
      create_callback_queues
      super
    end

    def already_running
      duplicate_batches.count > 0
    end

    def duplicate_batches
      rel = self.class.where(:guid => guid, :state => "running")
      return rel if new_record?

      rel.where("id <> ?", id)
    end

    def expired?
      expire_at < DateTime.now
    end

    def has_errors
      error?
    end

    def kill
      Process.kill('TERM', pid)
    end

    def kill!
      Process.kill('KILL', pid)
    end

    def multiples_allowed
      true
    end

    def on_ensure *args, &block
      if block_given?
        @ensure_callbacks << block
      else
        @ensure_callbacks << args.shift
      end
    end

    def on_failure *args, &block
      if block_given?
        @failure_callbacks << block
      else
        @failure_callbacks << args.shift
      end
    end

    def on_success *args, &block
      if block_given?
        @success_callbacks << block
      else
        @success_callbacks << args.shift
      end
    end

    def run_ensure_callbacks
      Batchy.configure.global_ensure_callbacks.each do | ec |
        ec.call(self)
      end
      ensure_callbacks.each do | ec |
        ec.call(self)
      end
    end

    def run_success_callbacks
      Batchy.configure.global_success_callbacks.each do | sc |
        sc.call(self)
      end
      success_callbacks.each do | sc |
        sc.call(self)
      end
    end

    def run_failure_callbacks
      Batchy.configure.global_failure_callbacks.each do | fc |
        fc.call(self)
      end
      failure_callbacks.each do | fc |
        fc.call(self)
      end
    end

    private

    def create_callback_queues
      @success_callbacks = []
      @failure_callbacks = []
      @ensure_callbacks = []
    end
  end
end