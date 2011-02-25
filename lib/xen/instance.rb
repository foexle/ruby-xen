module Xen
  class Instance
    attr_accessor :name, :memory, :dom_id, :vcpus, :state, :time

    def initialize(name, options = {})
      @name = name
      @memory, @dom_id, @vcpus, @state, @time = options.values_at(:memory, :dom_id, :vcpus, :state, :time)
    end
  end
end
