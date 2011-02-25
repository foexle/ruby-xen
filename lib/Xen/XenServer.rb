module Xen
  class XenServer
    def initialize
      
    end

    def list_all
      domus = {}
      output = `xm list`
      output.each { |domu|
        domus << serialize_dom_info(domu)
      }
      return domus
    end

    def success?(var)
      if var == 0 then
        true
      else
        false
      end
    end

    def update
      @domus = {}
      output = `xm list`
		
      output.each { |line|
        line.grep(/(.*)\s+(\d+)\s+(\d+)\s+(\d+)\s+(.*?)\s+(\d+.\d)/) {
          @domus[$1.strip] = XenInstance.new($1.strip,
            :id => $2.strip,
            :memory => $3.strip,
            :vcpus => $4.strip,
            :state => $5.strip,
            :time => $6.strip )
        }
      }
      nil
    end
	
    def slices
      self.update
	        
      rslt = []
      @domus.each_key { |k|
        rslt << k
      }
      rslt
    end
	
    def has?(name)
      self.update
	        
      if @domus.has_key? name then
        true
      else
        false
      end
    end
	
    def get(name)
      domu = `xm list #{name}`
      return serialize_dom_info(domu)
    end
        
    def migrate(name, destination)
      if self.has? name then
        `xm migrate --live #{name} #{destination}`
        self.success? $?
      else
        false
      end
    end

  end

  private

  def serialize_dom_info(domu)
    domu.grep(/(.*)\s+(\d+)\s+(\d+)\s+(\d+)\s+(.*?)\s+(\d+.\d)/) {
      domu_info[$1.strip] = XenInstance.new($1.strip,
        :id => $2.strip,
        :memory => $3.strip,
        :vcpus => $4.strip,
        :state => $5.strip,
        :time => $6.strip )
    }
    return domu_info
  end
end
