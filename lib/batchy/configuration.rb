module Batchy
  class Configuration
  
    # Whether the batch can run multiple processes
    # with the same GUID. If set to false,
    # a request to run a batch while another
    # with the same GUID is still running will result
    # in an ignored state and the batch will not run  
    # Defaults to true
    attr_writer :allow_duplicates
    def allow_duplicates
      @allow_duplicates ||= true
    end

    # When a batch encounters an error, the error is caught
    # and logged while the batch exits with an "errored" state.
    # If you wish to error to continue to be raised up
    # the stack, set this to true
    # Defaults to false
    attr_writer :raise_errors
    def raise_errors
      @raise_errors ||= false
    end

    # Global callbacks will be called on all batches. They
    # will be added to the batch on initialization and
    # so they will be executed first, before any batch-specific
    # callbacks

    # Global callback for failures
    @global_failure_callbacks = []
    def add_global_failure_callback *args, &block
      @global_failure_callbacks << block
    end

    # Global callback for successes
    @global_success_callbacks = []
    def add_global_success_callback *args, &block
      @global_success_callbacks << block
    end

    # Global callbacks that execute no matter
    # what the end state
    @global_ensure_callbacks = []
    def add_global_ensure_callback *args, &block
      @global_ensure_callbacks << block
    end
  end
end