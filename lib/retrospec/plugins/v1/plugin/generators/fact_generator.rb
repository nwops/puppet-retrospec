require_relative 'facter'

module Retrospec
  module Puppet
    module Generators
      class FactGenerator < Retrospec::Plugins::V1::Plugin
        attr_reader :template_dir, :context, :module_path, :fact_name, :config_data

        # retrospec will initilalize this class so its up to you
        # to set any additional variables you need to get the job done.
        def initialize(module_path, spec_object = {})
          # below is the Spec Object which serves as a context for template rendering
          # you will need to initialize this object, so the erb templates can get the binding
          # the SpecObject can be customized to your liking as its different for every plugin gem.
          @module_path = module_path
          @config_data = spec_object
          @context = OpenStruct.new(:fact_name => spec_object[:name])
        end

        # used to display subcommand options to the cli
        # the global options are passed in for your usage
        # http://trollop.rubyforge.org
        # all options here are available in the config passed into config object
        def self.run_cli(global_opts)
          sub_command_opts = Trollop.options do
            banner <<-EOS
Generates a new fact with the given name

            EOS
            opt :name, 'The name of the fact you wish to create', :type => :string, :require => :true, :short => '-n'
          end
          unless sub_command_opts[:name]
            Trollop.educate
            exit 1
          end
          plugin_data = global_opts.merge(sub_command_opts)
          Retrospec::Puppet::Generators::FactGenerator.new(plugin_data[:module_path], plugin_data)
        end

        def fact_name
          context[:fact_name]
        end

        def facter_dir
          @facter_dir ||= File.join(module_path, 'lib', 'facter')
        end

        def facter_spec_dir
          @facter_spec_dir ||= File.join(module_path, 'spec', 'unit', 'facter')
        end

        def fact_name_path
          File.join(facter_dir, "#{fact_name}.rb")
        end

        # generates a fact file with the given name based on the template in the templates directory
        def generate_fact_file
          safe_create_template_file(fact_name_path, File.join(template_dir, 'fact.rb.retrospec.erb'), context)
          generate_fact_spec_files
        end

        # returns an array of fact files found in the facter directory
        def fact_files
          @fact_files ||= Dir.glob(File.join(facter_dir, '*.rb')).sort
        end

        # generates spec files for each fact defined in the fact file
        # returns a array of generated spec files
        def generate_fact_spec_files
          spec_files = []
          fact_files.each do | fact_file|
            fact_file_data = Retrospec::Puppet::Generators::Facter.load_fact(fact_file)
            fact_file_data.facts.each do |name, fact_data|
              # because many facts can be in a single file we want to create a unique file for each fact
              fact_spec_path = File.join(facter_spec_dir, "#{name}_spec.rb")
              spec_files << fact_spec_path
              safe_create_template_file(fact_spec_path, File.join(template_dir, 'fact_spec.rb.retrospec.erb'), fact_data)
            end
          end
          spec_files
        end

        # the template directory located inside the your retrospec plugin gem
        # you should not have to modify this unless you move the templates directory
        # for now we are going to choose the correct template directory that contains the templates
        def template_dir
          unless @template_dir
            external_templates = File.expand_path(File.join(config_data[:template_dir], 'facts', 'fact.rb.retrospec.erb'))
            if File.exist?(external_templates)
              @template_dir = File.join(config_data[:template_dir], 'facts')
            else
              @template_dir = File.expand_path(File.join(File.dirname(File.dirname(__FILE__)), 'templates', 'facts'))
            end
          end
          @template_dir
        end
      end
    end
  end
end
