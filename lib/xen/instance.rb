module Xen
  class Instance
    attr_accessor :name, :memory, :dom_id, :vcpus, :state, :time

    def initialize(name, options=())
      @name=name
      @memory=options[:memory]
      @dom_id=options[:dom_id]
      @vcpus=options[:vcpus]
      @state=options[:state]
      @time=options[:time]
    end

  end
end