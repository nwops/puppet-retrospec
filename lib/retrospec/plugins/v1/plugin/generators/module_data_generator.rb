require 'retrospec/plugins/v1/module_helpers'
require 'retrospec/plugins/v1'
require 'retrospec/plugins/v1/plugin/generators/base_generator'

module Retrospec
  module Puppet
    module Generators
      class ModuleDataGenerator < Retrospec::Puppet::Generators::BaseGenerator
        attr_reader :module_name, :spec_object
        def initialize(module_path, spec_object = {})
          super
          @plural_name = 'module_data'
          @spec_object = spec_object
          @singular_name = @plural_name
        end

        def module_name
          @module_name ||= Utilities::PuppetModule.instance.module_name.split(%r{-|\/}).last
        end

        # @return [String] backend type
        def backend_type
          context.backend_type
        end

        # @return [String] backend name
        def backend_name
          context.backend_name
        end

        # @return [String] function type
        def backend_function_type
          context.function_type
        end

        def generate_module_data_for_hiera
          safe_create_directory_files(template_dir, module_path, context, /functions/)
        end

        def generate_hiera_file
          path = File.join(module_path, 'hiera.yaml')
          template = File.join(template_dir, 'hiera.yaml.retrospec.erb')
          safe_create_template_file(path, template, self)
        end

        def generate_module_data_for_function(_type)
          data = { :name => backend_name,
                   :type => backend_function_type,
                   :test_type => 'rspec',
                   :module_name => module_name }.merge(spec_object)
          f = FunctionGenerator.new(module_path, data)
          ext = backend_function_type == 'native' ? 'pp' : 'rb'
          template_path = File.join(template_dir, 'functions', backend_function_type, "function_#{backend_type}.#{ext}.retrospec.erb")
          f.generate_function_file(template_path)
          generate_hiera_file
        end

        def template_dir
          external_templates = File.expand_path(File.join(config_data[:template_dir], @plural_name))
          if File.exist?(external_templates)
            File.join(config_data[:template_dir], 'module_data')
          else
            File.expand_path(File.join(File.dirname(File.dirname(__FILE__)), 'templates', @plural_name))
          end
        end

        def run
          if backend_type == 'hiera'
            generate_module_data_for_hiera
          else
            generate_module_data_for_function(backend_type)
          end
        end

        # used to display subcommand options to the cli
        # the global options are passed in for your usage
        # http://optimist.rubyforge.org
        # all options here are available in the config passed into config object
        # returns the parameters
        def self.run_cli(global_opts, args = ARGV)
          backend_types = %w(hiera data_hash lookup_key data_dig)
          sub_command_opts = Optimist.options(args) do
            banner <<-EOS
Generate the scaffolding required to use data in a module from hiera or a custom hiera backend.
 * Data in module is only available in puppet 4.7+
 * Hiera 5 backends are only available in puppet 4.9+
    * https://docs.puppet.com/puppet/4.10/hiera_custom_backends.html

Examples:
  retrospec puppet module_data -b data_hash -n my_custom_hash -t native
  retrospec puppet module_data  (uses defaults which is the hiera backend type, most people will want this )

Options:

            EOS
            opt :backend_type, "Which hiera backend type to use (#{backend_types.join(', ')})",
                :type => :string, :required => false, default: 'hiera', :short => '-b'
            opt :backend_name, 'The name of the custom backend',
                :type => :string, :required => false, default: 'custom', :short => '-n'
            opt :function_type, 'What type of function to create the backend type with (native or v4)',
                :type => :string, :required => false, default: 'native', :short => '-t'
          end
          unless backend_types.include?(sub_command_opts[:backend_type])
            Optimist.die :backend_type, "must be one of #{backend_types.join(', ')}"
          end
          unless %w(native v4).include?(sub_command_opts[:function_type])
            Optimist.die :function_type, "must be one of #{%w(native v4).join(', ')}"
          end

          plugin_data = global_opts.merge(sub_command_opts)
          plugin_data
        end
      end
    end
  end
end
