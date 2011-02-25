require 'log/logger'
require 'system/command'

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
        domu = System::Command.exec_command("xm list #{name}", :command_level => 1)

        if domu[:exitstatus] == 0
          domu[:stdout] = instance_from_output(domu[:stdout].split("\n").last)
        end

        return domu
      end

      # Vars = :id, :name, :memory, :hdd, :cpus, :status
      def create(attributes = {})
        logger.info("Creating new Xen instance with name: #{attributes[:name]} ...")

        password = Xen::Util.generate_root_password

        if password[:exitstatus] == 0
          command = <<-cmd
            xen-create-image --hostname=#{attributes[:name]} --password=#{attributes[:stdout]}
                             --vcpus=#{attributes[:cpus]} --memory=#{attributes[:memory]} --size=#{attributes[:hdd]}
                             --arch=amd64 --dist=lucid
          cmd

          System::Command.exec_command(command, :command_level => 2)
        end
      end

      def instances_from_output(output)
        output[:stdout].split("\n")[1..-1].map do |line|
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

    def paused?
      state == 'p'
    end
  end
end
