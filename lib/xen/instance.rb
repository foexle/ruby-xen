require 'log/logger'
require 'system/command'
require 'xen/server'
require 'xen/util'

module Xen
  class Instance
    attr_accessor :name, :memory, :dom_id, :vcpus, :state, :time

    class << self
      def all
        output = System::Command.exec_command("xm list" , :command_level => 1)
        return [] unless output[:exitstatus] == 0

        instances_from_output(output[:stdout])
      end

      def find_by_name(name)
        output = System::Command.exec_command("xm list #{name}", :command_level => 1)

        instance_from_output(output[:stdout].split("\n").last)
      end
      alias :[] :find_by_name

      # Vars = :id, :name, :memory, :hdd, :cpus, :status
      def create(attributes = {})
        logger.info("Creating new Xen instance with name #{attributes[:hostname]} ...")

        password = Xen::Util.generate_root_password

        if password[:exitstatus] == 0
          command = <<-cmd.split("\n").map { |l| l.strip }.join(" ").squeeze(' ')
            xen-create-image --hostname=#{attributes[:hostname]} --ip=#{attributes[:ip]} --password=#{password[:stdout]}
                             --vcpus=#{attributes[:vcpus]} --memory=#{attributes[:memory]} --size=#{attributes[:size]}
                             --arch=#{attributes[:arch]} --dist=#{attributes[:dist]}
          cmd

          System::Command.exec_command(command, :command_level => 2)
        end
      end

      def instances_from_output(output)
        output.split("\n")[1..-1].map do |line|
          instance_from_output(line)
        end
      end

      def instance_from_output(output)
        logger.debug("Finding #{output} ...")

        return unless output.match(/(.*)\s+(\d+)\s+(\d+)\s+(\d+)\s+(.*?)\s+(\d+.\d)/)

        Instance.new($1.strip, :dom_id => $2.strip, :memory => $3.strip, :vcpus => $4.strip, :state => $5.strip.gsub("-","")) #:time => $6.strip)
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
      System::Command.exec_command("xm create #{name}.cfg", :command_level => 2)
    end

    def reboot
      System::Command.exec_command("xm reboot #{dom_id}", :command_level => 2)
    end

    def shutdown
      System::Command.exec_command("xm shutdown #{dom_id}", :command_level => 2)
    end

    def migrate(destination)
      System::Command.exec_command("xm migrate --live #{name} #{destination}", :command_level => 2)
    end

    def destroy
      System::Command.exec_command("xm destroy #{dom_id}", :command_level => 1)
    end

    def pause
      System::Command.exec_command("xm pause #{dom_id}", :command_level => 1) unless paused?
    end

    def unpause
      System::Command.exec_command("xm unpause #{dom_id}", :command_level => 1) if paused?
    end

    def state_text
      case state
      when 'r': 'running'
      when 'b': 'blocked'
      when 's': 'shutdown'
      when 'c': 'crashed'
      when 'd': 'dying'
      when 'p': 'paused'
      end
    end

    def running?
      state == 'r'
    end

    def blocked?
      state == 'b'
    end

    def shutdown?
      state == 's'
    end

    def crashed?
      state == 'c'
    end

    def dying?
      state == 'd'
    end

    def paused?
      state == 'p'
    end
  end
end
