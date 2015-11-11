require 'ostruct'

# this is required to use when processing erb templates
class OpenStruct
  def get_binding
    binding()
  end
end
# we could also create a new instance of the type and use instances methods to retrieve many things
# Puppet::Type.type(type_name) after loading the file
module Retrospec
  module Puppet
    class Type

      # loads the type_file and provider_file if given
      # determines if type or provider is being used and
      # evals the code
      def self.load_type(type_file, provider_file=nil)
        require type_file
        if provider_file
          require provider_file
          file = provider_file
          @model = OpenStruct.new(:name => nil, :file => file,
                                  :class_methods => [], :instance_methods => [],
                                  :properties => [], :parameters => []
                                  )
          t = eval(File.read(file))
          @model.parameters = t.resource_type.parameters
          @model.properties = t.resource_type.validproperties
          @model.name = t.name
          @model.class_methods = t.methods(false)
          @model.instance_methods = t.instance_methods(false)
          @model
        else
          file = type_file
          @model = OpenStruct.new(:name => nil, :file => file,
                                  :properties => [], :instance_methods => [],
                                  :parameters => [], :methods_defined => [])
          t = eval(File.read(file))
          @model.name = t.name
          @model.parameters = t.parameters
          @model.properties = t.properties.collect {|t| t.name }
          @model.instance_methods = t.instance_methods(false)
          @model
        end
        @model
      end

      def self.type(name, options={}, &block)
        ::Puppet::Type.type(name)
      end

      # I don't know of a better way to get the name of the type
      def self.newtype(name, options={}, &block)
        ::Puppet::Type.type(name)
      end

    end
  end
end
