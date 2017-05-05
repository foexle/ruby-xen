require 'log/logger'
require 'system/exception'
# This class is for executing any system command. All ruby implemented system commands like ` ` or system() are
# not strong and effectivly enough.
# You have the opportunity to set a command_level, you own failure message and an expected_exit_status.
#
# Command_level: This means how importend is the exit_code > 0 to the running application
# Expected_exit_status: Sometime you have a system command they runs without errors or only a warning but with an other exit code as 0.
# Message: Your own failure message.
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
      return self
    end

    def error?
      ![0, expected_exit_status].include?(exit_status)
    end

    def error_message
      message || output
    end

    def log
      case @command_level
      when LEVEL_WARN
          logger.warn(error_message)
          raise System::Exception::WarningException.new(error_message, command, exit_status)
      when LEVEL_FATAL 
          logger.fatal(error_message)
          raise System::Exception::CriticalException.new(error_message, command, exit_status)
      end
    end

    def logger
      self.class.logger
    end


  end
end
