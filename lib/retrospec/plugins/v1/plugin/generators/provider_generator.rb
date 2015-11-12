require_relative 'parsers/type'
require 'facets'

module Retrospec::Puppet::Generators
  class ProviderGenerator < Retrospec::Plugins::V1::Plugin
    attr_reader :template_dir, :context
    attr_accessor :provider_type

    # retrospec will initaialize this class so its up to you
    # to set any additional variables you need in the context in feed the templates.
    def initialize(module_path, spec_object = {})
      super
      # below is the Spec Object which serves as a context for template rendering
      # you will need to initialize this object, so the erb templates can get the binding
      # the SpecObject can be customized to your liking as its different for every plugin gem.
      @context = OpenStruct.new(:provider_name => spec_object[:name], :type_name => spec_object[:type])
      @provider_type = context.type_name
    end

    # returns the path to the templates
    # first looks inside the external templates directory for specific file
    # then looks inside the gem path templates directory, which is really only useful
    # when developing new templates.
    def template_dir
      unless @template_dir
        external_templates = File.expand_path(File.join(config_data[:template_dir], 'providers', 'provider_template.rb.retrospec.erb'))
        if File.exist?(external_templates)
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
      sub_command_opts = Trollop.options do
        banner <<-EOS
Generates a new provider with the given name.

        EOS
        opt :name, 'The name of the type you wish to create', :type => :string, :required => true, :short => '-n'
        opt :type, 'The type name of the provider', :type => :string, :required => true, :short => '-t'
      end
      unless sub_command_opts[:name]
        Trollop.educate
        exit 1
      end
      plugin_data = global_opts.merge(sub_command_opts)
      plugin_data
    end

    def provider_dir
      File.join(module_path, 'lib', 'puppet', 'provider')
    end

    def type_dir
      File.join(module_path, 'lib', 'puppet', 'type')
    end

    # returns the type file that the provider uses
    # if the type file does not exist it assumes a core puppet type
    # because we could potentially dealing with multiple
    def type_file(p_type = provider_type)
      if core_types.include?(p_type)
        type_file = "puppet/type/#{p_type}"
      else
        type_file = File.join(type_dir, "#{p_type}.rb")
      end
      type_file
    end

    def provider_spec_dir
      File.join(module_path, 'spec', 'unit', 'puppet', 'provider')
    end

    def provider_name_path
      File.join(provider_dir, provider_type, "#{provider_name}.rb")
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
        provider_file_data = Retrospec::Puppet::Type.load_type(type_file(t_name), provider_file)
        provider_file_data.type_name = t_name # add the provider type
        # because many facts can be in a single file we want to create a unique file for each fact
        provider_spec_path = File.join(provider_spec_dir, t_name, "#{provider_file_data.name}_spec.rb")
        spec_files << provider_spec_path
        safe_create_template_file(provider_spec_path, File.join(template_dir, 'provider_spec.rb.retrospec.erb'), provider_file_data)
      end
      spec_files
    end

    private

    def core_types
      %w(augeas
         computer
         cron
         exec
         file
         filebucket
         group
         host
         interface
         k5login
         macauthorization
         mailalias
         maillist
         mcx
         mount
         nagios_command
         nagios_contact
         nagios_contactgroup
         nagios_host
         nagios_hostdependency
         nagios_hostescalation
         nagios_hostextinfo
         nagios_hostgroup
         nagios_service
         nagios_servicedependency
         nagios_serviceescalation
         nagios_serviceextinfo
         nagios_servicegroup
         nagios_timeperiod
         notify
         package
         resources
         router
         schedule
         scheduled_task
         selboolean
         selmodule
         service
         ssh_authorized_key
         sshkey
         stage
         tidy
         user
         vlan
         yumrepo
         zfs
         zone
         zpool )
    end
  end
end
