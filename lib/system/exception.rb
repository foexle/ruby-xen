module System
  module Exception
    class CriticalException < ::Exception
      def initialize(message, command, exit)
        @message = message
        @command = command
        @exit = exit
      end

      def to_s
        <<EOF
      #{@message}

      Command (#{@command}) exiting with code #{@exit}

EOF
      end
    end

    class WarningException < ::Exception
      def initialize(message, command, exit)
        @message = message
        @command = command
        @exit = exit
      end

      def to_s
        <<EOF
      #{@message}

      Command (#{@command}) exiting with code #{@exit}

EOF
      end
    end

  end
end