# require 'retrospec/plugins/v1/module_helpers'
# require 'retrospec/plugins/v1'
require_relative 'resource_base_generator'

module Retrospec
  module Puppet
    module Generators
      class DataTypeGenerator < Retrospec::Puppet::Generators::ResourceBaseGenerator

        def initialize(module_path, spec_object = {})
          super
          @singular_name = 'datatype'
          @plural_name = 'types'
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
            # next unless definition.resource_type == ::Puppet::Pops::Model::ResourceTypeDefinition
            datatype.generate_spec_file
          end.flatten
        end

        # def run
        #   generate_lib_files
        #   generate_spec_files
        # end

        # def generate_lib_files
        #   []
        # end

        # def generate_spec_files
        #   template_file = File.join(template_dir,spec_template_file )
        #   context = load_context_data
        #   logger.debug("\nUsing template #{template_file}\n")
        #   safe_create_template_file(item_spec_path, template_file, context)
        #   item_spec_path
        # end

        # def item_path
        #   File.join(lib_path, "#{item_name}.pp")
        # end

        # def spec_path
        #   File.join(module_path, 'spec', plural_name)
        # end

        # def lib_path
        #   File.join(module_path, plural_name)
        # end

        # returns the path to the templates
        # first looks inside the external templates directory for specific file
        # then looks inside the gem path templates directory, which is really only useful
        # when developing new templates.
        def template_dir
          if config_data[:template_dir]
            external_templates = Dir.glob(File.expand_path(File.join(config_data[:template_dir], 'datatypes', '*.erb')))
          end
          if external_templates and external_templates.count > 0
            File.join(config_data[:template_dir], 'datatypes')
          else
            File.expand_path(File.join(File.dirname(File.dirname(__FILE__)), 'templates', 'datatypes'))
          end
        end

        # def self.generate_spec_files(module_path, config_data)
        #   files = []
        #   manifest_files(module_path).map do |file|
        #     datatype = new(module_path, config_data.merge({:manifest_file => file}))
        #     #next unless hostclass.resource_type == ::Puppet::Pops::Model::HostClassDefinition
            
        #     #hostclass.generate_spec_file
        #   end
        # end

        

        # def self.manifest_files(module_path)
        #   Dir.glob(File.join(module_path, 'types', '**', '*.pp'))
        # end

        # # used to display subcommand options to the cli
        # # the global options are passed in for your usage
        # # http://optimist.rubyforge.org
        # # all options here are available in the config passed into config object
        # # returns the parameters
        # def self.run_cli(global_opts, args=ARGV)
        #   sub_command_opts = Optimist.options(args) do
        #     banner <<-EOS
        #     ""
        #     EOS
        #     opt :name, "The name of the datatype you wish to create including the namespace", :type => :string, :required => true, :short => '-n'
        #   end
        #   unless sub_command_opts[:name]
        #     Optimist.educate
        #     exit 1
        #   end
        #   plugin_data = global_opts.merge(sub_command_opts)
        #   plugin_data
        # end
      end
    end
  end
end

