require 'log/logger'

module System
  class Command
    LEVEL_WARN  = 1
    LEVEL_FATAL = 2

    attr_reader :command, :expected_exit_status, :message, :command_level, :output, :exit_status

    class << self
      def logger
        @@logger ||= Log::Logger.log
      end
    end

    def initialize(command, options = {})
      @command       = command
      @expected_exit = options[:expected_exit_status] || 0
      @message       = options[:message] unless options[:message].nil? || options[:message].empty?
      @command_level = options[:command_level] || LEVEL_WARN
    end

    def execute
      @output = `#{command} 2>&1`
      @exit_status  = $?.exitstatus
      log if error?
    end

    def error?
      ![0, expected_exit_status].include?(exit_status)
    end

    def error_message
      message || output
    end

    def log
      case @command_level
      when LEVEL_WARN: logger.warn(error_message)
      when LEVEL_FATAL: logger.fatal(error_message)
      end
    end

    def logger
      self.class.logger
    end


  end
end
