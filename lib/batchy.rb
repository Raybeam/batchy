require 'active_record'
require 'active_support'
require 'addressable/uri'
require 'andand'
require 'state_machine/core'
require 'sys/proctable'

require 'batchy/batch'
require 'batchy/configuration'
require 'batchy/version'

require 'generators/batchy/templates/migration'

module Batchy
  extend self

  # Get configuration options
  # If a block is provided, it sets the contained
  # configuration options.
  def configure
    @configuration ||= Configuration.new
    if block_given?
      yield @configuration
    end
    @configuration
  end

  # Issue a SIGTERM to all expired batches.  This will result in an error
  # being raised inside the batchy block and a final error state
  # for the batch.
  def clean_expired
    Batchy::Batch.expired.each do | b |
      b.kill
    end
  end

  # This is dangerous.  If you open a batch inside your main program
  # this process could kill your main application.
  # It is turned off by default.
  def clean_expired!
    unless Batchy.configure.allow_mass_sigkill
      Kernel.warn 'Mass sigkill is not allowed.  Use "clean_expired" to issue a mass SIGTERM, or set the "allow_mass_sigkill" config option to true'
      return false
    end

    Batchy::Batch.expired.each do | b |
      b.kill!
    end
  end

  # Sets all configuration options back to
  # default
  def clear_configuration
    @configuration = nil
  end

  # Get the current batch
  def current
    @current ||= nil
  end

  # Sets the logger for batchy
  def logger
    @logger ||= Logger.new(STDOUT)
    @logger
  end

  def logger=(logger)
    @logger = logger
  end

  # The main entry point for batchy.  It wraps code in a batchy
  # block.  Batchy handles errors, logging and allows for
  # callbacks.
  def run *args
    options = args.extract_options!

    batch = Batch.create options
    batch.start!
    return false if batch.ignored?
    begin
      # Set the proclist process name
      previous_name = $0
      $0 = batch.name if Batchy.configure.name_process

      # Set parent if there is an outer batch
      if Batchy.current
        batch.parent = Batchy.current
      end

      # Set current batch
      @current = batch

      # Save everything before yielding
      batch.save!
      
      yield batch

      batch.run_success_callbacks
    rescue Exception => e
      batch.error = e

      batch.run_failure_callbacks
    ensure
      batch.finished_at = DateTime.now
      batch.finish!

      batch.run_ensure_callbacks

      # Set current batch to parent (or nil if no parent)
      @current = batch.parent

      # Set proclist process name back
      $0 = previous_name
    end
  end

  class Error < StandardError
  end 
end