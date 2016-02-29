require_relative 'serializers/rspec_dumper'
require 'puppet'
require 'puppet/pops'

module Retrospec
  module Puppet
    module Generators
      class NodeGenerator < Retrospec::Puppet::Generators::ResourceBaseGenerator
        # retrospec will initilalize this class so its up to you
        # to set any additional variables you need to get the job done.
        def initialize(module_path, spec_object = {})
          super
          @singular_name = 'node'
          @plural_name = 'hosts'
        end

        def spec_template_file
          'node_spec.rb.retrospec.erb'
        end

        def self.generate_spec_files(module_path)
          files = []
          manifest_files(module_path).each do |file|
            definition = new(module_path, {:manifest_file => file})
            next if definition.resource_type != ::Puppet::Pops::Model::ResourceTypeDefinition
            files << definition.generate_spec_file
          end
          files
        end

      end

    end
  end
end
