require 'retrospec/plugins/v1/context_object'
module Retrospec
  module Puppet
    # this object is passed to the templates for erb template rendering
    # you can use data contained in this object in your templates
    class SpecObject < Retrospec::Plugins::V1::ContextObject
      attr_reader :instance, :module_path, :module_name, :all_hiera_data, :config
      attr_accessor :enable_beaker_tests, :parameters, :types, :resources, :type

      # @param mod_path [String] - the path to the module
      # @param instance_data [Hash]
      # @param config_data [Hash] - retrospec config data from config file and cli
      def initialize(mod_path, instance_data, config_data)
        @instance = instance_data
        @config = config_data
        @module_path = mod_path
        all_hiera_data
      end

      # @return [String] - the name of the module
      def module_name
        instance.module_name
      end

      # @return [Array] - returns an array of puppet types found in the manfiests
      # this is a list of defined and class types
      def types
        instance.types
      end

      # @return [Hash] - return a hash of all the params found in provided hostclass only
      # @param [String] - the name of the hostclass
      # does not search for manual lookups using the hiera or lookup function
      def class_hiera_data(classname)
        data = {}
        found_type = host_classes.find { |t| t.name == classname }
        return data unless found_type
        found_type.arguments.each do |k, _v|
          key = "#{found_type.name}::#{k}"
          data[key] = nil
        end
        data
      end

      # @return [Array] - an array of all the hostclasses
      def host_classes
        types.find_all { |t| t.type == :hostclass }
      end

      # @return [Hash] - return a hash of all the params found in all hostclasses
      # @param [String] - the name of the hostclass
      # does not search for manual lookups using the hiera or lookup function
      # @note this stays in memory, which should not cause a problem when the program
      # quits and the user wants to run again, but if some external tool keeps this in memory
      # the data would never be refreshed
      def all_hiera_data
        @all_hiera_data ||= begin
          host_classes.each_with_object({}) do |t, obj|
            t.arguments.each do |k, _v|
              key = "#{t.name}::#{k}"
              obj[key] = nil
            end
          end
        end
      end

      # @return [Boolean] - true if the user wants to enable beaker tests
      def enable_beaker_tests?
        config[:enable_beaker_tests]
      end

      # allows the user to use the variable store to resolve the variable if it exists
      # looks up the varible name in the variable store
      # @param [String] - the name of the variable
      # @return [String] -  the value of the variable if found other returns variable
      def variable_value(variable_name)
        VariableStore.resolve(variable_name)
      end

      def fact_name
        instance[:name]
      end
    end
  end
end
