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

      # Gets all running instances on dom0
      def all
        get_all = System::Command.new("sudo xm list" , :command_level => 1)
        get_all.execute
        return [] unless get_all.exit_status == 0

        instances_from_output(get_all.output)
      end

      # Gets an instance object
      # ==Params:
      # => +name+:  Name of instance
      def find_by_name(name)
        find = System::Command.new("sudo xm list #{name}", :command_level => 1)
        find.execute
        instance_from_output(find.output.split("\n").last)
      end
      alias :[] :find_by_name

      # Gets all attributs of an instance
      
      def find_attributes_by_name(name)
        find = System::Command.new("sudo xm list #{name}", :command_level => 1)
        find.execute
        attributes_from_output(find.output)
      end

      # Vars = :id, :name, :memory, :hdd, :cpus, :status
      # Note: debootstrap installation is the slowest, better are copy in xen
      def create(attributes = {})
        logger.info("Creating new Xen instance with name #{attributes[:name]} ...")

        exist_instance = find_by_name(attributes[:name])
        if exist_instance
          Logger.info("Running instance detected. Shutting down to create a new one")
          exist_instance.shutdown
        end
        
        password = Xen::Util.generate_root_password

        if password.exit_status == 0
          command = <<-cmd.split("\n").map { |l| l.strip }.join(' ').squeeze(' ')
            sudo xen-create-image --hostname=#{attributes[:name]} --ip=#{attributes[:ip]} --password=#{password[:stdout].strip}
                             --vcpus=#{attributes[:vcpus]} --memory=#{attributes[:memory]} --size=#{attributes[:size]}
                             --arch=#{attributes[:arch]} --dist=#{attributes[:dist]} --force &
          cmd

          create_image = System::Command.new(command, :command_level => 2)
          attributes.merge(:password => password.output.strip)
          create_image.execute
        end
      end

      def start(name)
        instance = new(name)
        instance.start
        return instance
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
      start = System::Command.new("sudo xm create #{name}.cfg", :command_level => 2)
      start.execute
      update_info
    end


    def reboot
      reboot = System::Command.new("sudo xm reboot #{dom_id}", :command_level => 2)
      reboot.execute
    end

    def shutdown
      shutdown = System::Command.new("sudo xm shutdown #{dom_id}", :command_level => 2)
      shutdown.execute
    end

    def migrate(destination)
      migrate = System::Command.new("sudo xm migrate --live #{name} #{destination}", :command_level => 2)
      migrate.execute
    end

    def destroy
      destroy = System::Command.new("sudo xm destroy #{dom_id}", :command_level => 1)
      destroy.execute
    end

    def pause
      unless paused?
        pause = System::Command.new("sudo xm pause #{dom_id}", :command_level => 1)
        pause.execute
      end
    end

    def unpause
      if paused?
        unpause = System::Command.new("sudo xm unpause #{dom_id}", :command_level => 1)
        unpause.execute
      end
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
