module Xen
  class Instance
    attr_accessor :name, :memory, :dom_id, :vcpus, :state, :time

    def initialize(name, options = {})
      @name = name
      @memory, @dom_id, @vcpus, @state, @time = options.values_at(:memory, :dom_id, :vcpus, :state, :time)
    end

    class << self
      def find_by_name(name)
        domu = System::Command.exec_command("xm list #{name}", :command_level => 1)

        if domu[:exitstatus] == 0
          domu[:stdout] = instance_from_output(domu[:stdout].split("\n").last)
        end

        return domu
      end
    end

    protected

      def instance_from_output(output)
        return unless output.match(/(.*)\s+(\d+)\s+(\d+)\s+(\d+)\s+(.*?)\s+(\d+.\d)/)

        Instance.new($1.strip, :dom_id => $2.strip, :memory => $3.strip, :vcpus => $4.strip, :state => $5.strip.gsub("-","")) #:time => $6.strip)
      end
  end
end
