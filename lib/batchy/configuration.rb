module Batchy
  class Configuration

    def initialize
      @global_success_callbacks = []
      @global_failure_callbacks = []
      @global_ensure_callbacks = []
      @global_ignore_callbacks = []
    end
  
    # Whether the batch can run multiple processes
    # with the same GUID. If set to false,
    # a request to run a batch while another
    # with the same GUID is still running will result
    # in an ignored state and the batch will not run  
    # Defaults to true
    attr_writer :allow_duplicates
    def allow_duplicates
      @allow_duplicates.nil? ? true : @allow_duplicates
    end

    # When a batch encounters an error, the error is caught
    # and logged while the batch exits with an "errored" state.
    # If you wish to error to continue to be raised up
    # the stack, set this to true
    # Defaults to false
    attr_writer :raise_errors
    def raise_errors
      @raise_errors.nil? ? false : @raise_errors
    end

    # This sets the name of the process in the proclist to
    # the name of the current batch.  It defaults to true
    attr_writer :name_process
    def name_process
      @name_process.nil? ? true : @name_process
    end

    # This library has the ability to issue a SIGKILL
    # to all expired batch processes.  If batchy is
    # being used by a server process or the main
    # application process, this will kill it.  Only
    # set this to true if you're sure you're only
    # going to use batches as async processes that
    # nothing else depends on.  Defaults to false.
    attr_writer :allow_mass_sigkill
    def allow_mass_sigkill
      @allow_mass_sigkill.nil? ? false : @allow_mass_sigkill
    end

    # Global callbacks will be called on all batches. They
    # will be added to the batch on initialization and
    # so they will be executed first, before any batch-specific
    # callbacks

    # Global callback for failures
    attr_reader :global_failure_callbacks
    def add_global_failure_callback *args, &block
      @global_failure_callbacks << block
    end

    # Global callback for ignore
    attr_reader :global_ignore_callbacks
    def add_global_ignore_callback *args, &block
      @global_ignore_callbacks << block
    end

    # Global callback for successes
    attr_reader :global_success_callbacks
    def add_global_success_callback *args, &block
      @global_success_callbacks << block
    end

    # Global callbacks that execute no matter
    # what the end state
    attr_reader :global_ensure_callbacks
    def add_global_ensure_callback *args, &block
      @global_ensure_callbacks << block
    end

    # Sets the prefix of all batchy processes
    # Defaults to [BATCHY]
    attr_writer :process_name_prefix
    def process_name_prefix
      @process_name_prefix.nil? ? "[BATCHY]" : @process_name_prefix
    end
  end
end