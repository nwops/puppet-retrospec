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
          @context = OpenStruct.new(:manifest_file => spec_object[:file], :content => nil)
        end

        # def self.manifest_files
        #   @manifest_files ||= Dir.glob(File.join(module_path, '*.pp'))
        # end
        #
        # def self.generate_spec_files
        #   files = []
        #   manifest_files.each do |file|
        #     template_file = File.join(template_dir, 'hostclass.rb.retrospec.erb')
        #     safe_create_template_file(item_spec_path, template_file, context)
        #     item_spec_path
        #   end
        # end

        def generate_spec_file
          template_file = File.join(template_dir, 'hostclass.rb.retrospec.erb')
          context.content = generate_content
          safe_create_template_file(item_spec_path, template_file, context)
          item_spec_path
        end

        def manifest_file
          context.manifest_file
        end

        def generate_content
          class_def = ast.body
          parameters = class_def.parameters
          dumper = Retrospec::Puppet::RspecDumper.new
          content = dumper.dump(ast)
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

        # returns the name of the first time found in the file
        # for files that have multiple types, we just don't care since it doesn't
        # follow the style guide
        def type_name
          ast.eContents.first.name
        end

        # returns the filename of the type
        def generate_file_name(type_name)
          tokens = type_name.split('::')
          file_name = tokens.pop
          "#{file_name}_spec.rb"
        end

        # generates a file path for spec tests based on the resource name.  An added option
        # is to generate directory names for each parent resource as a default option
        def item_spec_path
          file_name = generate_file_name(type_name)
          tokens = type_name.split('::')
          # if there are only two tokens ie. tomcat::params we dont need to create a subdirectory
          if tokens.count > 2
            # this is a deep level resource ie. tomcat::config::server::connector
            # however we don't need the tomcat directory so we can just remove it
            # this should leave us with config/server/connector_spec.rb
            tokens.delete_at(0)
            # remove the last token since its the class name
            tokens.pop
            # so lets make a directory structure out of it
            dir_name = File.join(tokens) # config/server
            dir_name = File.join(spec_path, dir_name, file_name) # spec/classes/tomcat/config/server
          else
            dir_name = File.join(spec_path, file_name)
          end
          dir_name
        end

        private

        def ast
          parser = ::Puppet::Pops::Parser::EvaluatingParser.new
          result = parser.parse_file(manifest_file)
          ast = result.current
        end

      end

    end
  end
end
