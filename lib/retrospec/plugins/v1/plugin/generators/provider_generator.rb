require_relative 'parsers/type'
require 'facets'

module Retrospec::Puppet::Generators
  class ProviderGenerator < Retrospec::Plugins::V1::Plugin
    attr_reader :template_dir, :context

    # retrospec will initilalize this class so its up to you
    # to set any additional variables you need in the context in feed the templates.
    def initialize(module_path, spec_object={})
      super
      # below is the Spec Object which serves as a context for template rendering
      # you will need to initialize this object, so the erb templates can get the binding
      # the SpecObject can be customized to your liking as its different for every plugin gem.
      @context = OpenStruct.new(:provider_name => spec_object[:name], :provider_type => spec_object[:type])
    end

    def template_dir
      unless @template_dir
        external_templates = File.expand_path(File.join(config_data[:template_dir], 'providers', 'provider_template.rb.retrospec.erb'))
        if File.exists?(external_templates)
          @template_dir = File.join(config_data[:template_dir], 'types')
        else
          @template_dir = File.expand_path(File.join(File.dirname(File.dirname(__FILE__)), 'templates', 'providers'))
        end
      end
      @template_dir
    end

    # used to display subcommand options to the cli
    # the global options are passed in for your usage
    # http://trollop.rubyforge.org
    # all options here are available in the config passed into config object
    # returns the parameters
    def self.run_cli(global_opts)
      sub_command_opts = Trollop::options do
        banner <<-EOS
Generates a new provider with the given name.

        EOS
        opt :name, "The name of the type you wish to create", :type => :string, :required => true, :short => '-n'
        opt :type, "The type name of the provider", :type => :string, :required => true, :short => '-t'
      end
      unless sub_command_opts[:name]
        Trollop.educate
        exit 1
      end
      plugin_data = global_opts.merge(sub_command_opts)
      plugin_data
    end

    def provider_dir
      @provider_dir ||= File.join(module_path, 'lib', 'puppet', 'provider', provider_type)
    end

    # returns the type file that the provider uses
    # if the type file does not exist it assumes a core puppet type
    def type_file(p_type=provider_type)
      type_file = File.join(module_path, 'lib', 'puppet', 'type', "#{p_type}.rb")
      unless File.exists? type_file
        type_file = "puppet/type/#{p_type}"
      end
      type_file
    end

    def provider_spec_dir
      @provider_spec_dir ||= File.join(module_path, 'spec', 'unit', 'puppet', 'provider', provider_type)
    end

    def provider_name_path
      File.join(provider_dir, "#{provider_name}.rb")
    end

    def provider_type
      @provider_type ||= context.provider_type
    end

    def provider_name
      context.provider_name
    end

    def generate_provider_files
      safe_create_template_file(provider_name_path, File.join(template_dir, 'provider_template.rb.retrospec.erb'), context)
      provider_name_path
    end

    def generate_provider_spec_files
      provider_files = Dir.glob(File.join(provider_dir, '**', '*.rb')).sort
      spec_files = []
      provider_files.each do |provider_file|
        t_name = File.basename(File.dirname(provider_file))
        begin
          provider_file_data = Retrospec::Puppet::Type.load_type(type_file(t_name), provider_file)
        rescue LoadError
          puts "Error loading file #{type_file}".fatal
          return spec_files
        end
        # because many facts can be in a single file we want to create a unique file for each fact
        provider_spec_path = File.join(provider_spec_dir, "#{provider_file_data.name}_spec.rb")
        spec_files << provider_spec_path
        safe_create_template_file(provider_spec_path, File.join(template_dir, 'provider_spec.rb.retrospec.erb'), provider_file_data)
      end
      spec_files
    end
  end
end
