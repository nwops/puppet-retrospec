require_relative 'base_generator'
require_relative 'serializers/rspec_dumper'
require 'puppet'
require 'puppet/pops'

module Retrospec
  module Puppet
    module Generators
      class HostClassGenerator < Retrospec::Puppet::Generators::BaseGenerator
        # retrospec will initilalize this class so its up to you
        # to set any additional variables you need to get the job done.
        def initialize(module_path, spec_object = {})
          super
          @plural_name = 'classes'
          @singular_name = 'class'
        end

        def generate_spec_files
          template_file = File.join(template_dir, 'hostclass.rb.retrospec.erb')
          safe_create_template_file(item_spec_path, template_file, context)
          item_spec_path
        end

        def generate_content(file)
          parser = ::Puppet::Pops::Parser::EvaluatingParser.new
          result = parser.parse_file(file)
          ast = result.current
          class_def = ast.body
          parameters = class_def.parameters
          dumper = Retrospec::Puppet::RspecDumper.new
          dumper.dump(ast)
        end

        # run is the main method that gets called automatically
        def run
          generate_spec_files
        end

        def item_path
          File.join(lib_path, "#{item_name}.pp")
        end

        def item_spec_path
          File.join(spec_path, "#{item_name}_spec.rb")
        end

        def spec_path
          File.join(module_path, 'spec', plural_name)
        end

        def lib_path
          File.join(module_path, 'manifests')
        end

      end

    end
  end
end
