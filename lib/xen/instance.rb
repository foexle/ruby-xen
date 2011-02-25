require 'log/logger'
require 'system/command'
require 'xen/server'
require 'xen/util'

# TODO extract sudo to be used as an option
module Xen
  class Instance
    STATE_RUNNING  = 'r'
    STATE_BLOCKED  = 'b'
    STATE_SHUTDOWN = 's'
    STATE_CRASHED  = 'c'
    STATE_DYING    = 'd'
    STATE_PAUSED   = 'p'

    attr_accessor :dom_id, :name, :memory, :vcpus, :state, :time

    class << self
      def all
        output = System::Command.exec_command("sudo xm list" , :command_level => 1)
        return [] unless output[:exitstatus] == 0

        instances_from_output(output[:stdout])
      end

      def find_by_name(name)
        output = System::Command.exec_command("sudo xm list #{name}", :command_level => 1)

        instance_from_output(output[:stdout].split("\n").last)
      end
      alias :[] :find_by_name

      def find_attributes_by_name(name)
        output = System::Command.exec_command("sudo xm list #{name}", :command_level => 1)
        attributes_from_output(output[:stdout])
      end

      # Vars = :id, :name, :memory, :hdd, :cpus, :status
      def create(attributes = {})
        logger.info("Creating new Xen instance with name #{attributes[:name]} ...")

        password = Xen::Util.generate_root_password

        if password[:exitstatus] == 0
          command = <<-cmd.split("\n").map { |l| l.strip }.join(" ").squeeze(' ')
            sudo xen-create-image --hostname=#{attributes[:name]} --ip=#{attributes[:ip]} --password=#{password[:stdout]}
                             --vcpus=#{attributes[:vcpus]} --memory=#{attributes[:memory]} --size=#{attributes[:size]}
                             --arch=#{attributes[:arch]} --dist=#{attributes[:dist]} && sudo xm start #{attributes[:name]}.cfg > /dev/null 2>&1 &
          cmd

          System::Command.exec_command(command, :command_level => 2)

          attributes.merge(:password => password[:stdout])
        end
      end

      def start(name)
        instance = new(name)
        instance.start
        instance
      end

      def instances_from_output(output)
        output.split("\n")[1..-1].map do |line|
          instance_from_output(line)
        end
      end

      def instance_from_output(output)
        logger.debug("Finding #{output} ...")

        attributes = attributes_from_output(output)
        return unless attributes

        Instance.new(attributes[:name], attributes) #:time => $6.strip)
      end

      def attributes_from_output(output)
        return unless output.match(/(.*)\s+(\d+)\s+(\d+)\s+(\d+)\s+(.*?)\s+(\d+.\d)/)

        { :name => $1.strip, :dom_id => $2.strip, :memory => $3.strip, :vcpus => $4.strip, :state => $5.strip.gsub("-","") }
      end

      def logger
        @@logger ||= Log::Logger.log(:log_level => Xen::Server::LOG_LEVEL)
      end
    end

    def initialize(name, options = {})
      @name = name
      @memory, @dom_id, @vcpus, @state, @time = options.values_at(:memory, :dom_id, :vcpus, :state, :time)
    end

    def start
      System::Command.exec_command("sudo xm create #{name}.cfg", :command_level => 2)
      update_info
    end

    def reboot
      System::Command.exec_command("sudo xm reboot #{dom_id}", :command_level => 2)
    end

    def shutdown
      System::Command.exec_command("sudo xm shutdown #{dom_id}", :command_level => 2)
    end

    def migrate(destination)
      System::Command.exec_command("sudo xm migrate --live #{name} #{destination}", :command_level => 2)
    end

    def destroy
      System::Command.exec_command("sudo xm destroy #{dom_id}", :command_level => 1)
    end

    def pause
      System::Command.exec_command("sudo xm pause #{dom_id}", :command_level => 1) unless paused?
    end

    def unpause
      System::Command.exec_command("sudo xm unpause #{dom_id}", :command_level => 1) if paused?
    end

    def state_text
      case state
      when STATE_RUNNING: 'running'
      when STATE_BLOCKED: 'blocked'
      when STATE_SHUTDOWN: 'shutdown'
      when STATE_CRASHED: 'crashed'
      when STATE_DYING: 'dying'
      when STATE_PAUSED: 'paused'
      end
    end

    def running?
      state == STATE_RUNNING
    end

    def blocked?
      state == STATE_BLOCKED
    end

    def shutdown?
      state == STATE_SHUTDOWN
    end

    def crashed?
      state == STATE_CRASHED
    end

    def dying?
      state == STATE_DYING
    end

    def paused?
      state == STATE_PAUSED
    end

    def update_info
      @memory, @dom_id, @vcpus, @state, @time = self.class.find_attributes_by_name(name).values_at(:memory, :dom_id, :vcpus, :state, :time)
    end
  end
end
