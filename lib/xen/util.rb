module Xen
  module Util
    class << self
      def generate_root_password
        System::Command.exec_command("pwgen 16 1", :command_level => 1)
      end
    end
  end
end
