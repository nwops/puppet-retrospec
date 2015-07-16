
module Utilities
  class SpecObject
    attr_reader :instance, :all_hiera_data
    attr_accessor :enable_beaker_tests, :parameters, :types, :resources, :type

    def initialize(mod_instance)
      @instance = mod_instance
      all_hiera_data
    end

    def types
      instance.types
    end

    def class_hiera_data(classname)
      data = {}
      types.each do |t|
        next unless t.type == :hostclass   #defines don't have hiera lookup values
        next unless t.name == classname
        t.arguments.each do |k, v|
          key = "#{t.name}::#{k}"
          data[key] = nil
        end
      end
      data
    end

    # gathers all the class parameters that could be used in hiera data mocking
    def all_hiera_data
      if @all_hiera_data.nil?
        @all_hiera_data = {}
        types.each do |t|
          next unless t.type == :hostclass   #defines don't have hiera lookup values
          t.arguments.each do |k, v|
            key = "#{t.name}::#{k}"
            @all_hiera_data[key] = nil
          end
        end
      end
      @all_hiera_data
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

    # allows the user to use the variable store to resolve the variable if it exists
    def variable_value(key)
      VariableStore.resolve(key)
    end

  end
end
