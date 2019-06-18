require_relative 'base_generator'
require_relative 'serializers/rspec_dumper'
require_relative 'serializers/rspec_dumper_full'

require 'puppet'
require 'puppet/pops'

module Retrospec
  module Puppet
    module Generators
      class ResourceBaseGenerator < Retrospec::Puppet::Generators::BaseGenerator
        # retrospec will initilalize this class so its up to you
        # to set any additional variables you need to get the job done.
        def initialize(module_path, spec_object = {})
          spec_object.merge!({:manifest_file => spec_object[:manifest_file],
            :content => nil, name: spec_object[:name]})
          super
        end

        def item_spec_path
          iname = type_name || item_name
          file_name = generate_file_name(iname.downcase)
          path = generate_path("#{file_name}_spec.rb", iname)
          File.join(spec_path, path )
        end

        def singular_name
          unless @singular_name
            raise NotImplementedError
          end
          @singular_name
        end

        def plural_name
          unless @plural_name
            raise NotImplementedError
          end
          @plural_name
        end

        def spec_template_file
          NotImplementedError
        end

        # used to display subcommand options to the cli
        # the global options are passed in for your usage
        # http://optimist.rubyforge.org
        # all options here are available in the config passed into config object
        # returns the parameters
        def self.run_cli(global_opts, args=ARGV)
          sub_command_opts = Optimist.options(args) do
            banner <<-EOS
            ""
            EOS
          end
          unless sub_command_opts[:manifest_file]
            Optimist.educate
            exit 1
          end
          plugin_data = global_opts.merge(sub_command_opts)
          plugin_data
        end

        def self.manifest_files(module_path)
          Dir.glob(File.join(module_path, 'manifests', '**', '*.pp'))
        end

        def self.generate_spec_files(module_path, config_data)
          manifests = manifest_files(module_path)
          files = Retrospec::Puppet::Generators::HostClassGenerator.generate_spec_files(module_path, config_data)
          files << Retrospec::Puppet::Generators::DataTypeGenerator.generate_spec_files(module_path, config_data)
          files << Retrospec::Puppet::Generators::DefinitionGenerator.generate_spec_files(module_path, config_data)
          files.flatten
        end

        def load_context_data
          context.content = generate_content
          context.parameters = parameters
          context.type_name = type_name
          context.resources = resources
          context.resource_type = resource_type
          context.resource_type_name = resource_type_name
          context
        end

        def generate_spec_file
          template_file = File.join(template_dir,spec_template_file )
          context = load_context_data
          logger.debug("\nUsing template #{template_file}\n")
          safe_create_template_file(item_spec_path, template_file, context)
          item_spec_path
        end

        def manifest_file
          context.manifest_file
        end

        # return a manifest body object
        def manifest_body
          ast.body.body || ast.body
        end

        def find_all_resources
          res = manifest_body.eAllContents.find_all do |p|
            p.class.to_s == 'Puppet::Pops::Model::ResourceExpression'
          end
        end

        # returns all the found resources
        def resources
          @resources ||= find_all_resources.map {|p| dumper.dump(p)}
        end

        def dumper
          @dumper ||= Retrospec::Puppet::RspecDumper.new
        end

        # this produces the content that will later be rendered in the template
        def generate_content
          content = dumper.dump(ast)
        end

        def parameters
          if ast.body.respond_to?(:parameters)
            args = ast.body.parameters || []
            dumper.dump(args)
          else
            []
          end
        end

        # run is the main method that gets called automatically
        def run
          generate_spec_file
        end

        def item_path
          File.join(lib_path, "#{item_name}.pp")
        end

        def spec_path
          File.join(module_path, 'spec', plural_name)
        end

        def lib_path
          File.join(module_path, 'manifests')
        end

        def resource_type
          ast.eContents.first.class
        end

        # returns the type of resource either the define, type, or class
        def resource_type_name
          case ast.eContents.first
          when ::Puppet::Pops::Model::HostClassDefinition
            'class'
          when ::Puppet::Pops::Model::ResourceTypeDefinition
            type_name
          else
            resource_type
          end
        end

        # returns the name of the first type found in the file
        # for files that have multiple types, we just don't care since it doesn't
        # follow the style guide
        def type_name
          ast.eContents.first.name if ast.eContents.first.respond_to?(:name)
        end

        def ast
          unless @ast
            parser = ::Puppet::Pops::Parser::EvaluatingParser.new
            result = parser.parse_file(manifest_file)
            @ast = result.current
          end
          @ast
        end
      end
    end
  end
end
