require 'yaml'

module Retrospec
  module Puppet
    module Generators
      class SchemaGenerator < Retrospec::Plugins::V1::Plugin
        attr_reader :template_dir, :context, :schema

        # retrospec will initilalize this class so its up to you
        # to set any additional variables you need to get the job done.
        def initialize(module_path, spec_object = {})
          super
          # below is the Spec Object which serves as a context for template rendering
          # you will need to initialize this object, so the erb templates can get the binding
          # the SpecObject can be customized to your liking as its different for every plugin gem.
          @context = OpenStruct.new(:puppet_context => spec_object[:puppet_context])
          @schema = base_schema
        end

        def description
          <<-EOF
# Created using puppet-retrospec - https://github.com/nwops/puppet-retrospec
# This schema file can be used to validate hiera data"
# http://www.kuwata-lab.com/kwalify/ruby/users-guide.01.html#schema
# To validate your hiera data against this schema install the kwalify gem
# 1. gem install kwalify
# 2. kwalify -lf #{schema_name}_schema.yaml hiera_data_file.yaml
# By default this schema is generic and only covers basic parameter types.
# You should update the schema to match your expected data types in your puppet classes
# or anywhere else you call hiera using the hiera() function.
          EOF
        end
        # used to display subcommand options to the cli
        # the global options are passed in for your usage
        # http://trollop.rubyforge.org
        # all options here are available in the config passed into config object
        # returns the parameters
        def self.run_cli(global_opts)
          sub_command_opts = Trollop.options do
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

        # generates the schema file
        def generate_schema_file
          safe_create_file(schema_path, "#{description}\n#{create_map_content.to_yaml}")
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

        # gathers all the class parameters that could be used in hiera data mocking
        # this is the only function that generates the necessary data to be used for schema
        # creation.
        def all_hiera_data
          if @all_hiera_data.nil?
            @all_hiera_data = {}
            types.each do |t|
              next unless t.type == :hostclass # defines don't have hiera lookup values
              t.arguments.each do |k, _v|
                key = "#{t.name}::#{k}"
                @all_hiera_data[key] = {'type' => type_mapper(_v.class.to_s), 'required' => is_required?(_v) }
              end
            end
          end
          @all_hiera_data
        end



        def is_required?(item)
          item.nil?
        end


        # map the puppet data type to a kwalify data type
        # str
        # int
        # float
        # number (== int or float)
        # text (== str or number)
        # bool
        # date
        # time
        # timestamp
        # seq
        # map
        # scalar (all but seq and map)
        # any (means any data)
        def type_mapper(data_type)
          case data_type
            when 'Puppet::Parser::AST::Variable'
              'any'
            when 'Puppet::Parser::AST::Boolean'
              'bool'
            when 'Puppet::Parser::AST::String'
              'str'
            when 'Puppet::Parser::AST::ASTHash'
              'map'
            when 'Puppet::Parser::AST::ASTArray'
              'seq'
            else
              'any'
          end
        end

        def base_schema
          @base_schema ||= {
            "type" => "map",
            "mapping" => {}
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

      end
    end
  end
end

