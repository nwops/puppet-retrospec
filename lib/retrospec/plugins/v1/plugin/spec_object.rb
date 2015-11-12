require 'retrospec/plugins/v1/context_object'
module Retrospec
  module Puppet
    # this object is passed to the templates for erb template rendering
    # you can use data contained in this object in your templates
    class SpecObject < Retrospec::Plugins::V1::ContextObject
      attr_reader :instance, :module_path, :module_name, :all_hiera_data, :config
      attr_accessor :enable_beaker_tests, :parameters, :types, :resources, :type

      def initialize(mod_path, instance_data, config_data)
        @instance = instance_data
        @config = config_data
        @module_path = mod_path
        all_hiera_data
      end

      def module_name
        instance.module_name
      end

      def types
        instance.types
      end

      def class_hiera_data(classname)
        data = {}
        types.each do |t|
          next unless t.type == :hostclass # defines don't have hiera lookup values
          next unless t.name == classname
          t.arguments.each do |k, _v|
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
            next unless t.type == :hostclass # defines don't have hiera lookup values
            t.arguments.each do |k, _v|
              key = "#{t.name}::#{k}"
              @all_hiera_data[key] = nil
            end
          end
        end
        @all_hiera_data
      end

      def enable_beaker_tests?
        config[:enable_beaker_tests]
      end

      # allows the user to use the variable store to resolve the variable if it exists
      def variable_value(key)
        VariableStore.resolve(key)
      end

      def fact_name
        instance[:name]
      end
    end
  end
end
