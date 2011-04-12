module Xen
  module Util
    class << self
      def generate_root_password
        pwgen = System::Command.new("pwgen 16 1", :command_level => 1)
        return pwgen.execute
      end
    end
  end
end
