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

  def configure
    @configuration ||= Configuration.new
    if block_given?
      yield @configuration
    end
    @configuration
  end

  def clean_expired
    Batchy::Batch.expired.each do | b |
      b.kill
    end
  end

  # This is dangerous.  If you open a batch inside your main program
  # this process could kill your main application.
  # TODO: Make it a configuration option to allow this, default to false
  def clean_expired!
    Batchy::Batch.expired.each do | b |
      b.kill!
    end
  end

  def clear_configuration
    @configuration = nil
  end

  def logger
    @logger ||= Logger.new(STDOUT)
    @logger
  end

  def logger=(logger)
    @logger = logger
  end

  def run *args
    options = args.extract_options!

    batch = Batch.create options
    batch.start!
    begin
      yield batch
    rescue Exception => e
      batch.error = "{#{e.message}\n#{e.backtrace.join('\n')}"
    ensure
      batch.finish!
    end
  end
end