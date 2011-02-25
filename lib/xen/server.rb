module Xen
  require File.dirname(__FILE__) + '/instance'
  require File.dirname(__FILE__) + "/../log/loghandler"
  require File.dirname(__FILE__) + "/../system/command"
  class Server
    
    # Loglevel
    # => 1 DEBUG
    # => 2 Info
    # => 3 Warning
    # => 4 Critcal
    LOG_LEVEL = 1

    def initialize
      Log::LibLoghandler.log({:log_level => LOG_LEVEL}).info("Handling xen task ...")
    end

    # List all instaces on dom0
    def list_all
      domus = {:domus=>{}}
      output = System::Command.exec_command("xm list" , :command_level => 1)

      if output[:exitstatus] == 0
        instances = output[:stdout].split("\n")
        instances.each { |domu|
          Log::LibLoghandler.log({:log_level => LOG_LEVEL}).debug("Finding #{domu} ...")
          domus[:domus].merge!(serialize_dom_info(domu))
        }
      end
      return domus
    end

    
    # Stats am mew instance
    # ==Params:
    # * +:name+ - Name of instance
    def start(name)
      return System::Command.exec_command("xm create #{name}.cfg", :command_level => 2)
    end

    # Vars = :id, :name, :memory, :hdd, :cpus, :status
    def create(vars)
      Log::LibLoghandler.log({:log_level => LOG_LEVEL}).info("Creating new Xen instance with name: #{vars[:name]} ...")
      pw_return = generate_root_pw
      if pw_return[:exitstatus] == 0
        return System::Command.exec_command("xen-create-image --hostname=#{vars[:name]} --vcpus=#{vars[:cpus]}
                                            --password=#{pw_return[:stdout]} --arch=amd64 --dist=lucid --memory=#{vars[:memory]}
                                            --size=#{vars[:hdd]}", :command_level => 2)
      end
      return pw
    end

    # Destory an instance 
    def destroy(name)
      instance = self.get(name)
      if instance[:exitstatus] == 0
        instance = System::Command.exec_command("xm destroy #{instance[:stdout]["#{name}"].dom_id}", :command_level => 1)
      end
      return instance
    end

    def pause(name)
      instance = self.get(name)
      if instance[:exitstatus] == 0
        unless instance[:stdout]["#{name}"].status == "p"
          System::Command.exec_command("xm pause #{instance[:stdout]["#{name}"].dom_id}", :command_level => 1)
        else
          System::Command.exec_command("xm unpause #{instance[:stdout]["#{name}"].dom_id}", :command_level => 1)
        end
      end
    end
	
    # Get instance informations
    def get(name)
      domu = System::Command.exec_command("xm list #{name}", :command_level => 1)
      if domu[:exitstatus] == 0
        domu[:stdout] = serialize_dom_info(domu[:stdout].split("\n").last)
      end
      return domu
    end
        
    def migrate(name, destination)
      if self.has? name then
        `xm migrate --live #{name} #{destination}`
        self.success? $?
      else
        false
      end
    end

  

    private

    def serialize_dom_info(domu)
      
      domu_info = {}
      domu.grep(/(.*)\s+(\d+)\s+(\d+)\s+(\d+)\s+(.*?)\s+(\d+.\d)/) {
        domu_info[$1.strip] = Instance.new($1.strip,
          :dom_id => $2.strip,
          :memory => $3.strip,
          :vcpus => $4.strip,
          :state => $5.strip.gsub("-",""))
          #:time => $6.strip)
      }
      
      return domu_info
    end

    def generate_root_pw()
      return System::Command.exec_command("pwgen 16 1", :command_level => 1)

    end
    
  end
end