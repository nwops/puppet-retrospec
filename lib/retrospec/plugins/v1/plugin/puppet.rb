require 'retrospec/plugins/v1/module_helpers'
require 'retrospec/plugins/v1'
require 'retrospec/config'
require_relative 'generators'
require_relative 'exceptions'
require_relative 'spec_object'
require 'erb'
require_relative 'template_helpers'
require 'fileutils'
require_relative 'puppet_module'
require 'retrospec/exceptions'
require_relative 'version'
require 'find'
require 'logger'
require 'puppet'

module Retrospec
  module Plugins
    module V1
      class Puppet < Retrospec::Plugins::V1::Plugin
        include Retrospec::Puppet::TemplateHelpers
        attr_reader :template_dir, :context, :manifest_files
        attr_accessor :manifest_dir

        # @param module_path [String] - the path to the module
        # @param config [Hash] -  the configuration, which is passed to the parent
        def initialize(module_path = nil, config = {})
          super
          ::Puppet[:environment] = 'retrospec'
          ::Puppet[:environmentpath] = Utilities::PuppetModule.base_environment_path
          @manifest_dir = File.join(module_path, 'manifests')
          # user supplied a template path or user wants to use local templates
          @template_dir = setup_user_template_dir(config_data[:template_dir], config_data[:scm_url], config_data[:ref])
        end

        # @return [Logger] - instance of a logger
        def self.logger
          @logger ||= begin
            require 'logger'
            log = Logger.new(STDOUT)
            if ENV['RETROSPEC_LOGGER_LEVEL'] == 'debug'
              log.level = Logger::DEBUG
            else
              log.level = Logger::INFO
            end
            log
          end
        end

        # @return [Hash] - the context generated after the module has been setup
        def post_init
          # before we validate the module directory we should ensure the module exists by creating it
          # validation also occurs when setting the module path
          # these are required because the puppet module creates a singleton with some cached values
          Utilities::PuppetModule.instance.module_dir_name = File.basename(module_path)
          Utilities::PuppetModule.instance.module_name = File.basename(module_path)
          Utilities::PuppetModule.instance.module_path = module_path
          Utilities::PuppetModule.create_tmp_module_path # this is required to finish initialization
          # setting the context is required to make other methods below work.  #TODO lazy create the context
          @context = ::Retrospec::Puppet::SpecObject.new(module_path, Utilities::PuppetModule.instance, config_data)
        end

        # if the module does not exist lets create it
        # this will create the module directory, manifests directory and basic init.pp file
        # if the manifest directory already exist but an init.pp file does not we do not creating
        # anything since it is not mandatory
        # I thought about using the the module face to perform this generation but it seems like its not
        # supported at this time, and you can't specify the path to generate the module in
        # generates a new puppet function file
        # @param args [Hash] - the main retrospec args from the config file or cli
        # @param plugin_data [Hash] - the cli args passed in for the generator
        def new_module(plugin_data, args)
          plugin_data = Retrospec::Puppet::Generators::ModuleGenerator.run_cli(plugin_data, args)
          # the user passed in /tmp/test1 and the name is irrelevent
          if ! File.exists?(plugin_data[:module_path])
            plugin_data[:module_path] = File.join(plugin_data[:module_path])
            # if the module path basename is the same as the module name
            # this is a parent directory or the module already exists
          elsif File.basename(plugin_data[:module_path]) != plugin_data[:name]
            plugin_data[:module_path] = File.join(plugin_data[:module_path], plugin_data[:name])
          end
          # we need to set this because the this class is created before we created the new module directory
          # so we now have to set the manifests and module directory
          self.module_path = plugin_data[:module_path]
          config_data[:module_path] = plugin_data[:module_path]
          self.manifest_dir = File.join(plugin_data[:module_path], 'manifests')
          f = Retrospec::Puppet::Generators::ModuleGenerator.new(plugin_data[:module_path], plugin_data)
          f.run(manifest_dir)
        end

        # used to display subcommand options to the global_config cli
        # the global options are passed in for your usage
        # http://trollop.rubyforge.org
        # all options here are available in the config passed into the initialize code
        # this is the only entry point into the plugin
        # @param global_opts [Hash] - the global options for retrospec supplied on the cli
        # @param global_config [Hash] - the global config file options
        # @param plugin_config [Hash] - the global config for the puppet plugin
        # @param args [Array] - the args passed in on the cli through ARGV, useful for testing
        def self.run_cli(global_opts, global_config, plugin_config, args=ARGV)
          template_dir = ENV['RETROSPEC_TEMPLATES_DIR'] || plugin_config['plugins::puppet::template_dir'] || File.expand_path('~/.retrospec/repos/retrospec-puppet-templates')
          scm_url = ENV['RETROSPEC_PUPPET_SCM_URL'] || plugin_config['plugins::puppet::templates::url']
          #scm_branch = ENV['RETROSPEC_PUPPET_SCM_BRANCH'] || plugin_config['plugins::puppet::templates::ref'] || 'master'
          # TODO next major release - remove the RETROSPEC_PUPPET_SCM_BRANCH as env setting
          scm_ref = ENV['RETROSPEC_PUPPET_SCM_REF'] || ENV['RETROSPEC_PUPPET_SCM_BRANCH'] || plugin_config['plugins::puppet::templates::ref'] || 'master'
          beaker_tests  = plugin_config['plugins::puppet::enable_beaker_tests'] || false
          # a list of subcommands for this plugin
          sub_commands  = %w(new_module new_task new_fact new_type new_provider new_function new_report module_data)
          if sub_commands.count > 0
            sub_command_help = "Subcommands:\n  #{sub_commands.join("\n  ")}\n"
          else
            sub_command_help = ''
          end
          plugin_opts = Trollop.options(args) do
            version "Retrospec puppet plugin: #{Retrospec::Puppet::VERSION} (c) Corey Osman"
            banner <<-EOS
Generates puppet rspec test code and puppet module components.

#{sub_command_help}

            EOS
            opt :template_dir, 'Path to templates directory (only for overriding Retrospec templates)', :type => :string,
            :required => false, :default => template_dir
            opt :scm_url, 'SCM url for retrospec templates', :type => :string, :required => false,
            :default => scm_url
            opt :ref, 'Branch you want to use for the retrospec template repo', :type => :string, :required => false,
            :default => scm_ref
            opt :enable_beaker_tests, 'Enable the creation of beaker tests', :require => false, :type => :boolean, :default => beaker_tests
            stop_on sub_commands
          end
          # the passed in options will always override the config file
          plugin_data = plugin_opts.merge(global_config).merge(global_opts).merge(plugin_opts).merge(plugin_config)
          # define the default action to use the plugin here, the default is run
          sub_command = (args.shift || :run).to_sym
          # create an instance of this plugin
          plugin = new(plugin_data[:module_path], plugin_data)
          # check if the plugin supports the sub command
          begin
            if plugin.respond_to?(sub_command)
              case sub_command
              when :new_module
                plugin.send(sub_command, plugin_data, args)
                plugin.post_init # finish initialization
              when :run
                plugin.post_init   # finish initialization
              when :new_type
                plugin.new_type(plugin_data, args)
              when :new_function
                plugin.new_function(plugin_data, args)
              when :new_task
                plugin.new_task(plugin_data, args)
              when :new_fact
                plugin.new_fact(plugin_data, args)
              when :new_provider
                plugin.new_provider(plugin_data, args)
              else
                plugin.post_init   # finish initialization
                plugin.send(sub_command, plugin_data[:module_path], plugin_data, args)
              end
              plugin.send(:run)
            else
              puts "The subcommand #{sub_command} is not supported or valid".fatal
              exit 1
            end
          rescue Retrospec::Puppet::InvalidModulePathError => e
            exit 1
          rescue Retrospec::Puppet::NoManifestDirError => e
            exit 1
          rescue Retrospec::Puppet::ParserError => e
            exit 1
          rescue Retrospec::Puppet::Generators::CoreTypeException => e
            puts e.message.fatal
          rescue Errno::ENOENT => e
            puts e.message
          rescue Exception => e
            puts e.message
            exit 1
          end
          plugin_data
        end

        # generates a new puppet task
        # @param args [Hash] - the main retrospec args from the config file or cli
        # @param config [Hash] - the cli args passed in for the generator
        # @return [Array] - returns the files paths that were generated
        def new_task(config, args)
          plugin_data = Retrospec::Puppet::Generators::TaskGenerator.run_cli(config, args)
          plugin_data[:puppet_context] = context
          t = Retrospec::Puppet::Generators::TaskGenerator.new(plugin_data[:module_path], plugin_data)
          t.run
          post_init
        end

        # generates module data files
        # @param args [Hash] - the main retrospec args from the config file or cli
        # @param config [Hash] - the cli args passed in for the generator
        # @param module_path [String] - the path to the module
        # @return [Array] - returns the files paths that were generated
        def module_data(module_path, config, args=[])
          plugin_data = Retrospec::Puppet::Generators::ModuleDataGenerator.run_cli(config, args)
          plugin_data[:puppet_context] = context
          p = Retrospec::Puppet::Generators::ModuleDataGenerator.new(module_path, plugin_data)
          p.run
        end

        # generates a new puppet report file
        # @param args [Hash] - the main retrospec args from the config file or cli
        # @param config [Hash] - the cli args passed in for the generator
        # @param module_path [String] - the path to the module
        # @return [Array] - returns the files paths that were generated
        def new_report(module_path, config, args=[])
          plugin_data = Retrospec::Puppet::Generators::ReportGenerator.run_cli(config, args)
          p = Retrospec::Puppet::Generators::ReportGenerator.new(module_path, plugin_data)
          p.run
        end

        # temporary disabling for future version
        # def new_schema(module_path, config, args=[])
        #   plugin_data = Retrospec::Puppet::Generators::SchemaGenerator.run_cli(config, args)
        #   plugin_data[:puppet_context] = context
        #   s = Retrospec::Puppet::Generators::SchemaGenerator.new(plugin_data[:module_path], plugin_data)
        #   s.generate_schema_file
        # end

        # generates a new puppet function file
        # @param args [Hash] - the main retrospec args from the config file or cli
        # @param config [Hash] - the cli args passed in for the generator
        # @return [Array] - returns the files paths that were generated
        def new_function(config, args)
          plugin_data = Retrospec::Puppet::Generators::FunctionGenerator.run_cli(config, args)
          f = Retrospec::Puppet::Generators::FunctionGenerator.new(plugin_data[:module_path], plugin_data)
          post_init
          f.generate_function_file
        end

        # generates function spec files
        # @param module_path [String] - the path to the module
        # @param config [Hash] - the configuration from the cli and retrospec
        # @return [Array] - returns the files paths that were generated
        def function_spec_files(module_path, config)
          f = Retrospec::Puppet::Generators::FunctionGenerator.new(module_path, config)
          f.generate_spec_files
        end

        # generates a new provider
        # @param args [Hash] - the main retrospec args from the config file or cli
        # @param config [Hash] - the cli args passed in for the generator
        # @return [Array] - returns the files paths that were generated
        def new_provider(config, args)
          plugin_data = Retrospec::Puppet::Generators::ProviderGenerator.run_cli(config, args)
          p = Retrospec::Puppet::Generators::ProviderGenerator.new(plugin_data[:module_path], plugin_data)
          post_init
          p.generate_provider_files
        end

        # generates provider spec files
        # @param module_path [String] - the path to the module
        # @param config [Hash] - the configuration from the cli and retrospec
        # @return [Array] - returns the files paths that were generated
        def provider_spec_files(module_path, config)
          t = Retrospec::Puppet::Generators::ProviderGenerator.new(module_path, config)
          t.generate_provider_spec_files
        end

        # generates a new type
        # @param args [Hash] - the main retrospec args from the config file or cli
        # @param config [Hash] - the cli args passed in for the generator
        # @return [Array] - returns the files paths that were generated
        def new_type(config, args)
          plugin_data = Retrospec::Puppet::Generators::TypeGenerator.run_cli(config, args)
          t = Retrospec::Puppet::Generators::TypeGenerator.new(plugin_data[:module_path], plugin_data)
          post_init
          t.generate_type_files
        end

        # generates spec files for a puppet type
        # @param module_path [String] - the path to the module
        # @param config [Hash] - the configuration from the cli and retrospec
        # @return [Array] - returns the files paths that were generated
        def type_spec_files(module_path, config)
          t = Retrospec::Puppet::Generators::TypeGenerator.new(module_path, config)
          t.generate_type_spec_files
        end

        # generates a new fact file
        # @param args [Hash] - the main retrospec args from the config file or cli
        # @param plugin_data [Hash] - the cli args passed in for the generator
        # @return [Array] - returns the files paths that were generated
        def new_fact(plugin_data, args)
          f = Retrospec::Puppet::Generators::FactGenerator.run_cli(plugin_data, args)
          post_init # finish initialization
          f.generate_fact_file
        end

        # generates the fact spec files
        # @param module_path [String] - the path to the module
        # @param config [Hash] - the configuration from the cli and retrospec
        # @return [Array] - returns the files paths that were generated
        def fact(module_path, config)
          f = Retrospec::Puppet::Generators::FactGenerator.new(module_path, config)
          f.generate_fact_spec_files
        end

        # this is the main method the starts all the magic
        # This also represents the order in which tasks are run
        def run
          run_pre_hook
          create_files
          run_post_hook
        end

        # the template directory located inside the retrospec gem
        # @return [String] - the path to the template directory
        def template_dir
          @template_dir ||= File.expand_path(File.join(File.dirname(__FILE__), 'templates'))
        end

        # runs a user defined hook called pre-hook
        def run_pre_hook
          hook_file = File.join(template_dir, 'pre-hook')
          run_hook(hook_file)
        end

        # @param hook_file [String] -  the path to the hook file
        # runs the hook file, on windows this is a bit tricky
        # because ruby may not be in the path
        # @note the hook file can only be a ruby script
        # this is because windows cannot execute just any script
        # and must be directed by prepending with the program name
        # unlike unix shebang magic
        def run_hook(hook_file)
          return unless File.exist?(hook_file)
          output = `ruby #{hook_file} #{module_path}`
          if $CHILD_STATUS.success?
            puts "Successfully ran hook: #{hook_file}".info
            puts output.info
          else
            puts "Error running hook: #{hook_file}".fatal
            puts output.fatal
          end
        end

        # runs a user defined hook called post-hook
        # if the template directory contains a post-hook file we run that
        def run_post_hook
          hook_file = File.join(template_dir, 'post-hook')
          run_hook(hook_file)
        end

        # this is the method that performs all the magic and creates all the files
        # @return [Boolean] - returns true if the method completed
        def create_files
          filter = /nodesets|acceptance|spec_helper_acceptance/ unless context.enable_beaker_tests?
          safe_create_module_files(template_dir, module_path, context, filter)
          fact(module_path, config_data)
          type_spec_files(module_path, config_data)
          provider_spec_files(module_path, config_data)
          function_spec_files(module_path, config_data)
          # FIXME temporary disabling to re-release in future update
          #new_schema(module_path, config_data)
          Retrospec::Puppet::Generators::ModuleGenerator.generate_metadata_file(context.module_name, config_data)
          Retrospec::Puppet::Generators::ResourceBaseGenerator.generate_spec_files(module_path, config_data)
          Retrospec::Puppet::Generators::AcceptanceGenerator.generate_spec_files(module_path, config_data) if context.enable_beaker_tests?
          Utilities::PuppetModule.clean_tmp_modules_dir
          true
        end

        # @return [String] - the description of this project
        def description
          'Generates puppet rspec test code based on the classes and defines inside the manifests directory'
        end

        # @return [String] - a list of puppet manifest files
        # @note menomizes the files
        def manifest_files
          @manifest_files ||= Dir.glob("#{manifest_dir}/**/*.pp")
        end
        alias :files :manifest_files

        # the main file type that is used to help discover what the module is
        # @return [String] - the puppet file extension
        def self.file_type
          '.pp'
        end
      end
    end
  end
end
