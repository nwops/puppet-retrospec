require 'ostruct'
require 'retrospec/plugins/v1/plugin/puppet_module'
# this is required to use when processing erb templates
class OpenStruct
  def get_binding
    binding
  end
end

module Retrospec
  module Puppet
    module Functions
      # for puppet 4 functions
      def self.create_function(func_name, function_base = nil, &block)
        # the bundled version of puppet with this gem is quite old and is preventing me from creating a function
        # to get the actual properties of it.  For now we can just skip the creation and stub enough functions
        # to get at the data.  However, if we just eval the file we can probably bypass all this code and use class
        # methods instead
        #require 'puppet/pops'
        #f = ::Puppet::Functions.create_function(func_name, function_base, &block)
        block.call
        @model.name = func_name
      end

      def self.load_function(file)
        begin
          ::Puppet.initialize_settings
        rescue
          # do nothing otherwise calling init twice raises an error
        end
        @model = OpenStruct.new(:name => File.basename(file, '.rb'), :dispatched_methods => {},
                                :required_methods => [])

        f = eval(File.read(file))
        @model.required_methods = find_required_methods(@model.name, @model.dispatched_methods.keys)
        @model
      end

      # figures out which methods need to be present in the function so that we can create a test for them
      def self.find_required_methods(name, dispatched_methods=[])
        if dispatched_methods.empty?
          [name]
        else
          dispatched_methods
        end
      end

      def self.dispatch(meth_name, &block)
          @params = [] # reset the variable
          args = block.call
          @model.dispatched_methods[meth_name] = {:name => meth_name, :args => args}
      end

      # this is a catch all method that helps us discover which dsl methods are used
      def self.method_missing(meth_sym, *arguments, &block)
        @params << {:name => meth_sym, :args => arguments}
      end

    end

    module Parser
      module Functions
        # for puppet 3 functions
        def self.newfunction(name, options = {}, &block)
          options.merge({:name => name})
        end

        # for puppet 4 functions
        def self.create_function(func_name, function_base = Function, &block)
          {:name => func_name }
        end

        def self.load_function(file)
          begin
            ::Puppet.initialize_settings
          rescue
            # do nothing otherwise calling init twice raises an error
          end
          @model = OpenStruct.new(:name => File.basename(file, '.rb'), :arity => nil, :doc => '', :type => nil,
                                  :class_methods => [], :instance_methods => [], :options => {})
          f = eval(File.read(file))
          @model.name = f[:name]
          @model.arity = f[:arity]
          @model.doc   = f[:doc]
          @model.type = f[:type]
          @model
        end
      end
    end
  end
end
