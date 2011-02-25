module Xen
  class XenInstance
    attr_accessor :name, :memory, :id, :vcpus, :state, :time

    def initialize(name, options=())
      @name=name
      @memory=options[:memory]
      @id=options[:id]
      @vcpus=options[:vcpus]
      @state=options[:state]
      @time=options[:time]
    end

    def running?
      output=`xm list #{@name}`
      $? == 0 ? true : false
    end

    def status?
      @state.gsub("-","")
    end
  end

  def create(name)
    if self.has? name then
      false
    else
      `xm create #{name}.cfg`
      self.success? $?
    end
  end

      def destroy(name)
      if self.has? name then
        `xm destroy #{name}`
        self.success? $?
      else
        false
      end
    end

    def pause(name)
      if self.has? name then
        if self.get(name).status? != "p" then
          `xm pause #{name}`
        else
          `xm unpause #{name}`
        end
        self.success? $?
      else
        false
      end
    end
end