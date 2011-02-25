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
      when LEVEL_WARN: logger.fatal(error_message)
      end
    end

    def logger
      self.class.logger
    end

    # Führt ein Systemkommando aus. Der unterschied zu system() ist, das hier der korrekte
    # Exitcode zurückgegeben wird und darüber hinaus, wird die STERR in die Log geschrieben.
    # Wie schwerwiegend der Fehler für das Backuptool ist, kann mittels des command_level entschieden werden.
    # Zusätzlich ist es bei einem Fehlerfall möglich, anstatt der STDERR eine individuelle Nachricht in die
    # Log auszugeben.
    # Einen Exitcode kann auch mit gegeben werden, um zu Fehler zu ignorieren, die keine Fehler sind.
    #
    # Level 1 => Warning
    # Level 2 => Fatal
    # ==Params
    # * +options+   -   Stellt eine Hash aus Werte dar:
    # =>                command => System Kommando
    # =>                command_level => Grad des Fehlers
    # =>                message => individuelle Fehler Message
    # =>                expected_exit => Welcher Exitcode wird erwartet
    #
    # ==Return
    # * +value_hash+    - stdout => Ausgabe der STDOUT (bei Fehlerfall ist die Fehlermessage enthalten)
    # =>                  exitstatus => Exitstatus des ausgeführten Kommandos
    def self.exec_command(command, options = {})
      return_hash = {}
      expected_exit = options[:expected_exit] || 0

      return_hash[:stdout] = `#{command} 2>&1`
      return_hash[:exitstatus] = $?.exitstatus


      unless return_hash[:exitstatus] == 0 || return_hash[:exitstatus] == expected_exit

        return_hash[:stdout] = options[:message] unless options[:message].nil? || options[:message].empty?

        case options[:command_level]
        when LEVEL_WARN: Log::Logger.log.warn(return_hash[:stdout])
        when LEVEL_FATAL: Log::Logger.log.fatal(return_hash[:stdout])
        end
      end
      return return_hash
    end

  end
end
