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

      def self.load_type(file)
        name = eval(File.read(file))
        require file
        t = ::Puppet::Type.type(name)
        @model = OpenStruct.new(:name => name, :file => file,
                                :properties => [], :instance_methods => [],
                                :parameters => [], :methods_defined => [])
        @model.parameters = t.parameters
        @model.properties = t.properties.collect { |p| p.name }
        @model.instance_methods = t.instance_methods(false)
        @model
      end

      # I don't know of a better way to get the name of the type
      def self.newtype(name, options={}, &block)
        name
      end

    end
  end
end
