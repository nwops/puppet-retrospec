require_relative 'parsers/function'
require_relative 'parsers/native_function'
module Retrospec
  module Puppet
    module Generators
      class FunctionGenerator < Retrospec::Plugins::V1::Plugin
        attr_reader :template_dir, :context
        # retrospec will initilalize this class so its up to you
        # to set any additional variables you need to get the job done.
        def initialize(module_path, spec_object = {})
          super
          # below is the Spec Object which serves as a context for template rendering
          # you will need to initialize this object, so the erb templates can get the binding
          # the SpecObject can be customized to your liking as its different for every plugin gem.
          @context = OpenStruct.new(:name => spec_object[:name], :return_type => spec_object[:return_type],
                                    :function_type => spec_object[:type],
                                    :test_type => spec_object[:test_type])
        end

        # Puppet currently has two versions of functions (v3, v4).  At the time of writing v4 is still new
        # and not used very much.  Because of this we will want to allow the user to pick which version of puppet function dsl
        # they wish to use.  Based on the version, a slightly different template will be rendered.  This method will return
        # the template dir based on the version passed in.
        # By default this method looks inside the user supplied template dir for existence of a template and if true returns that base path, if
        # false returns the template directory inside the gem location which is mainly used for development only.
        def template_dir
          external_templates = File.expand_path(File.join(config_data[:template_dir], 'functions',
                                                          function_type, "function_template#{function_ext}.retrospec.erb"))
          if File.exist?(external_templates)
            File.join(config_data[:template_dir], 'functions', function_type)
          else
            File.expand_path(File.join(File.dirname(File.dirname(__FILE__)), 'templates', 'functions', function_type))
          end
        end

        # returns v3,v4, native to specify the function type
        def function_type
          context.function_type
        end

        # used to display subcommand options to the cli
        # the global options are passed in for your usage
        # http://trollop.rubyforge.org
        # all options here are available in the config passed into config object
        # returns the parameters
        def self.run_cli(global_opts, args=ARGV)
          func_types = %w(v3 v4 native)
          func_type  = global_opts['plugins::puppet::default_function_version'] || 'v4'
          test_type  = global_opts['plugins::puppet::default_function_test_type'] || 'rspec'
          sub_command_opts = Trollop.options(args) do
            banner <<-EOS
Generates a new function with the given name.

            EOS
            opt :name, 'The name of the function you wish to create', :type => :string, :required => true, :short => '-n'
            opt :type, "The version type of the function (#{func_types.join(',')})", :type => :string, :required => false, :short => '-t',
                :default => func_type
            opt :test_type, 'The type of test file to create (rspec, ruby)', :default => test_type, :type => :string, :short => '-u'
            opt :return_type, 'The return type of the function (rvalue, statement)', :type => :string, :required => false,
                :short => '-r', :default => 'rvalue'
          end

          unless func_types.include? sub_command_opts[:type].downcase
            puts "Invalid type, must be one of #{func_types.join(',')}"
            Trollop.educate
            exit 1
          end
          unless sub_command_opts[:name]
            Trollop.educate
            exit 1
          end
          plugin_data = global_opts.merge(sub_command_opts)
          plugin_data
        end

        # returns the function directory to create the the function in
        def function_dir
          case function_type
          when 'v3'
            v3_function_dir
          when 'v4'
            v4_function_dir
          when 'native'
            native_function_dir
          end
        end

        # returns the path to the v3 function directory
        def v3_function_dir
          @v3_function_dir || File.join(module_path, 'lib', 'puppet', 'parser', 'functions')
        end

        # returns the path to the v4 function directory
        def v4_function_dir
          @v4_function_dir || File.join(module_path, 'lib', 'puppet', 'functions')
        end

        def native_function_dir
          @native_function_dir || File.join(module_path, 'functions')
        end

        # returns the path to the function using the function directory
        def function_path
          path = File.join(function_dir, function_name.to_s)
          path + function_ext
        end

        def function_ext
          function_type == 'native' ? '.pp' : '.rb'
        end

        # returns the name of the function
        def function_name
          context.name
        end

        def function_file_path
          File.join(template_dir, "function_template#{function_ext}.retrospec.erb")
        end

        # generates the function file based on the template and context
        def generate_function_file
          safe_create_template_file(function_path, function_file_path, context)
          function_path
        end

        # returns the path to the spec directory
        # because this can vary between test types and function types
        # there are many supporting functions to determine which directory to use
        def spec_file_dir
          case function_type
          when 'v3'
            v3_spec_dir
          when 'v4'
            v4_spec_dir
          when 'native'
            native_spec_dir
          end
        end

        def native_spec_dir
          File.join(module_path, 'spec', 'functions')
        end

        # returns the path to the v3 spec directory if using using rspec test type
        # the spec/functions is returned
        def v3_spec_dir
          if context.test_type == 'ruby'
            File.join(module_path, 'spec', 'unit', 'puppet', 'parser', 'functions')
          else
            File.join(module_path, 'spec', 'functions')
          end
        end

        # returns the path to the v4 spec directory if using using rspec test type
        # the spec/functions is returned
        def v4_spec_dir
          if context.test_type == 'ruby'
            File.join(module_path, 'spec', 'unit', 'puppet', 'functions')
          else
            File.join(module_path, 'spec', 'functions')
          end
        end

        # @return [Array] an array of functions found in either the v3,v4, native directories
        def discovered_functions
          Dir.glob([File.join(v3_function_dir, '*.rb'),
                    File.join(v4_function_dir, '*.rb'), File.join(native_function_dir, '*.pp')]).sort
        end

        # @return [Boolean] true if the function file is a native function
        def native_function?(function_file)
          # mod_name/functions
          File.basename(Pathname.new(function_file).parent) == 'functions' &&
            File.extname(function_file) == '.pp'
        end

        # @return [Boolean] true if the function file is a v4 function
        def v4_function?(function_file)
          # mod_name/lib/puppet/functions
          File.basename(Pathname.new(function_file).parent.parent) == 'functions'
        end

        # @return [Boolean] true if the function file is a v3 function
        def v3_function?(function_file)
          # mod_name/lib/puppet/parser/functions
          File.basename(Pathname.new(function_file).parent.parent) == 'parser'
        end

        # returns the template file name based on the test type
        def template_file
          if context.test_type == 'rspec'
            'function_rspec_template.retrospec.erb'
          else
            'function_ruby_template.retrospec.erb'
          end
        end

        # creates the spec files for the discovered_functions
        def generate_spec_files
          spec_files = []
          discovered_functions.each do |file|
            begin
              if v3_function?(file)
                context.function_type = 'v3'
                file_data = Retrospec::Puppet::Parser::Functions.load_function(file)
              elsif native_function?(file)
                context.test_type = 'rspec'
                context.function_type = 'native'
                file_data = Parsers::NativeFunction.load_function(file)
              else
                context.function_type = 'v4'
                file_data = Retrospec::Puppet::Functions.load_function(file)
              end
            rescue NoMethodError => e
              puts "Error evaluating function for #{file}, skipping".warning
              next
            rescue SyntaxError => e
              puts "Function syntax is bad for #{file}, skipping".warning
              next  # lets skip functions that have bad syntax
            end
            spec_path = File.join(spec_file_dir, "#{file_data.name}_spec.rb")
            spec_files << spec_path
            safe_create_template_file(spec_path, File.join(template_dir, template_file), file_data)
          end
          spec_files
        end
      end
    end
  end
end
