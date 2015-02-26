module Utilities
  class SpecObject
    attr_reader :instance
    attr_accessor :enable_beaker_tests, :parameters, :types, :resources, :type

    def initialize(mod_instance)
      @instance = mod_instance
    end

    def types
      instance.types
    end

    def module_name
      instance.module_name
    end

    def module_path
      instance.module_path
    end

    def get_binding
      binding
    end

    def enable_beaker_tests?
      @enable_beaker_tests == true
    end

  end
end
