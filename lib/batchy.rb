require 'active_record'
require 'active_support'
require 'addressable/uri'
require 'andand'
require 'state_machine/core'
require 'sys/proctable'

require 'batchy/batch'
require 'batchy/version'

require 'generators/batchy/templates/migration'

module Batchy
  extend self

  def logger
    @logger ||= Logger.new(STDOUT)
    @logger
  end

  def logger=(logger)
    @logger = logger
  end
end