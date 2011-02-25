require 'xen/instance'
require 'log/logger'
require 'system/command'

module Xen
  class Server
    # Loglevel
    # => 1 DEBUG
    # => 2 Info
    # => 3 Warning
    # => 4 Critcal
    LOG_LEVEL = 1

    class << self
      def logger
        @@logger ||= Log::Logger.log(:log_level => LOG_LEVEL)
      end
    end

    def initialize
      logger.info("Handling xen task ...")
    end

    def instances
      Xen::Instance.all
    end

    def logger
      self.class.logger
    end
  end
end