require_relative 'resource_base_generator'
require_relative 'serializers/rspec_dumper'
require 'puppet'
require 'puppet/pops'

module Retrospec
  module Puppet
    module Generators
      class DefinitionGenerator < Retrospec::Puppet::Generators::ResourceBaseGenerator
        # retrospec will initilalize this class so its up to you
        # to set any additional variables you need to get the job done.
        def initialize(module_path, spec_object = {})
          super
          @singular_name = 'define'
          @plural_name = 'defines'
        end

        def spec_template_file
          'definition_spec.rb.retrospec.erb'
        end

        def self.generate_spec_files(module_path, config_data)
          files = []
          manifest_files(module_path).each do |file|
            definition = new(module_path, config_data.merge({:manifest_file => file}))
            next unless definition.resource_type == ::Puppet::Pops::Model::ResourceTypeDefinition
            files << definition.generate_spec_file
          end
          files
        end

      end

    end
  end
end
