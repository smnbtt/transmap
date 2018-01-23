require "transmap/version"
require 'active_support/notifications'
require 'transmap/event_logger'
require 'transmap/mappers'
require 'logger'

# Provides methods for setting up the module configuration
module Transmap

  # Configuration container
  # @return [Transmap::Configuration]
  def self.configuration
    @configuration ||= Configuration.new
  end

  # Configure Transmap
  # @example How to configure Transmap
  #   Transmap.configure do |config|
  #     config.logger = Logger.new(STDOUT)
  #   end
  #
  # @yieldparam [Transmap::Configuration] configuration container
  def self.configure
    yield(configuration)
  end

  # @return [Logger] current logger instance
  def self.logger
    self.configuration.logger
  end

  # @attr [Logger] logger standard ruby logger, default STDOUT at DEBUG level
  class Configuration
    attr_accessor :logger

    def initialize
      @logger = Logger.new(STDOUT)
      @logger.level = :debug
    end
  end


end
