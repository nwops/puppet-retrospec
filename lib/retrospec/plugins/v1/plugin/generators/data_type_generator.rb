# require 'retrospec/plugins/v1/module_helpers'
# require 'retrospec/plugins/v1'
require_relative 'resource_base_generator'

module Retrospec
  module Puppet
    module Generators
      class DataTypeGenerator < Retrospec::Puppet::Generators::ResourceBaseGenerator

        def initialize(module_path, spec_object = {})
          super
          @singular_name = 'type_alias'
          @plural_name = 'type_aliases'
        end

        def self.manifest_files(module_path)
          Dir.glob(File.join(module_path, 'types', '**', '*.pp'))
        end

        def spec_template_file
          'datatype_spec.rb.retrospec.erb'
        end

        def load_context_data
          context.content = generate_content
          context.parameters = parameters
          context.type_name = type_name
          context.resource_type = resource_type
          context.resource_type_name = resource_type_name
          context
        end

        def self.generate_spec_files(module_path, config_data)
          manifest_files(module_path).map do |file|
            datatype = new(module_path, config_data.merge({:manifest_file => file}))
            next unless datatype.resource_type == ::Puppet::Pops::Model::TypeAlias
            datatype.generate_spec_file
          end.flatten
        end

        # returns the path to the templates
        # first looks inside the external templates directory for specific file
        # then looks inside the gem path templates directory, which is really only useful
        # when developing new templates.
        def template_dir
          if config_data[:template_dir]
            external_templates = Dir.glob(File.expand_path(File.join(config_data[:template_dir], 'type_aliases', '*.erb')))
          end
          if external_templates and external_templates.count > 0
            File.join(config_data[:template_dir], 'type_aliases')
          else
            File.expand_path(File.join(File.dirname(File.dirname(__FILE__)), 'templates', 'type_aliases'))
          end
        end
      end
    end
  end
end

