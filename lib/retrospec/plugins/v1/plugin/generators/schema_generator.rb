require 'yaml'
require_relative 'serializers/schema_dumper'

module Retrospec
  module Puppet
    module Generators
      class SchemaGenerator < Retrospec::Plugins::V1::Plugin
        attr_reader :template_dir, :schema
        attr_accessor :context
        # retrospec will initilalize this class so its up to you
        # to set any additional variables you need to get the job done.
        def initialize(module_path, spec_object = {})
          super
          # below is the Spec Object which serves as a context for template rendering
          # you will need to initialize this object, so the erb templates can get the binding
          # the SpecObject can be customized to your liking as its different for every plugin gem.
          @context = OpenStruct.new(:puppet_context => spec_object[:puppet_context], :map_content => '',
          :raw_maps => '',:parameter_count => '',:schema_path => '', :schema_name => '')
          @schema = base_schema
          @parameter_count = 0
        end

        # returns the path to the templates
        # first looks inside the external templates directory for specific file
        # then looks inside the gem path templates directory, which is really only useful
        # when developing new templates.
        def template_dir
          external_templates = File.expand_path(File.join(config_data[:template_dir], 'schemas', 'schema_file.yaml.retrospec.erb'))
          if File.exist?(external_templates)
            File.join(config_data[:template_dir], 'schemas')
          else
            File.expand_path(File.join(File.dirname(File.dirname(__FILE__)), 'templates', 'schemas'))
          end
        end

        # used to display subcommand options to the cli
        # the global options are passed in for your usage
        # http://trollop.rubyforge.org
        # all options here are available in the config passed into config object
        # returns the parameters
        def self.run_cli(global_opts, args=ARGV)
          sub_command_opts = Trollop.options(args) do
            banner <<-EOS
Generates a kwalify schema based off class parameters.

            EOS
          end
          plugin_data = global_opts.merge(sub_command_opts)
          plugin_data
        end

        # creates the schema in ruby object format
        def create_map_content
          all_hiera_data.each do |name, opts|
            add_mapping(name => opts)
          end
          schema
        end

        def schema_name
          puppet_context.module_name || File.basename(module_path)
        end

        # absolute path of schema file
        def schema_path
          File.join(module_path, "#{schema_name}_schema.yaml")
        end

        # generates the schema file, using a template
        def generate_schema_file
          map_content = create_map_content
          context.map_content = map_content.to_yaml
          context.raw_maps = map_content
          context.parameter_count = @parameter_count
          context.schema_path = schema_path
          context.schema_name = schema_name
          template_file = File.join(template_dir, 'schema_file.yaml.retrospec.erb')
          safe_create_template_file(schema_path, template_file, context)
          schema_path
        end

        # example
        # "motd::motd_content" => {
        #   "type" => "str",
        #   "required" => false
        # },
        def add_mapping(map_value)
          schema['mapping'].merge!(map_value)
        end

        def types
          context.puppet_context.types
        end

        private

        def dumper
          @dumper || Retrospec::Puppet::SchemaDumper.new
        end

        # generates a class or defination map
        def generate_type_map(puppet_type)
          type_name = puppet_type.type.to_s
          arg_map = {}
          #arg_map = {'mapping' => {}, 'required' => false, 'type' => 'map' }
          puppet_type.arguments.each do |k, _v|
            key = "#{puppet_type.name}::#{k}"
            kwalify_type = dumper.to_kwalify_type(_v)
            @parameter_count = @parameter_count + 1
            arg_map.deep_merge!(generate_map(key, _v, kwalify_type))
          end
          t_map = {type_name => { 'type' => 'map', 'mapping' => arg_map}}
        end

        # returns a hash of parameters with their classes
        def parameter_schema(found_types)
          parameter_data = {}
          found_types.each do |t|
            parameter_data = parameter_data.deep_merge(generate_type_map(t))
          end
          parameter_data
        end

        # gathers all the class parameters that could be used in hiera data mocking
        # this is the only function that generates the necessary data to be used for schema
        # creation.
        def all_hiera_data
          if @all_hiera_data.nil?
            @all_hiera_data = parameter_schema(types)
          end
          @all_hiera_data
        end

        def is_required?(item)
          item.nil?
        end

        def base_schema
          @base_schema ||= {
            "type" => "map",
            "mapping" => {
              "hostclass" => {
                "type" => "map",
                "mapping" => {}
              },
              "definition" => {
                "type" => "map",
                "mapping" => {}
              }
            }
          }
        end

        def any_map
          {"=" => {
              "type" => "any",
              "required" => false
            }
          }
        end

        def puppet_context
          context.puppet_context
        end

        # conversion table from ruby types to kwalify types
        def type_table
          @type_table ||= {
            'Array'=>"seq",
            'Hash'=>"map",
            'String'=>"str",
            'Integer'=>"int",
            'Float'=>"float",
            'Numeric'=>"number",
            'Date'=>"date",
            'Time'=>"timestamp",
            'Object'=>"any",
            'FalseClass' => 'bool',
            'TrueClass' => 'bool',
            'Fixnum' => 'number',
            'NilClass' => 'any',
            'Puppet::Parser::AST::Variable' => 'any',
            'Puppet::Parser::AST::Boolean' => 'bool',
            'Puppet::Parser::AST::String' => 'str',
            'Puppet::Parser::AST::ASTHash' => 'map',
            'Puppet::Parser::AST::ASTArray' => 'seq',
          }
        end

        # convert the given class to a kwalify class, defaults to any
        def type_map(klass)
          type_table[klass.to_s] || 'any'
        end

        # given a kwalify key undefined error
        # this method will produce a map of how the key should be defined
        # example
        #"motd::motd_content" => {
        #   "type" => "str",
        #   "required" => false
        # },
        def generate_map(key, value, value_type)
          case value_type
            when 'seq'
              {key => {
                "type" => 'seq',
                "sequence" => [{'type' => 'str'}],
                "required" => is_required?(value)
              }}
            when 'map'
              {key => {
                "type" => 'map',
                "mapping" => {'=' => {'type' => 'any', 'required' => false}},
                "required" => is_required?(value)
              }}
            else
              {key => {
                "type" => value_type,
                "required" => is_required?(value)
              }}
          end
        end
      end
    end
  end
end
