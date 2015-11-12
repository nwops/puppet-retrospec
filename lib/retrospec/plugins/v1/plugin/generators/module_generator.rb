require 'retrospec/plugins/v1/module_helpers'
require 'retrospec/plugins/v1'

module Retrospec
  module Puppet
    module Generators
      class ModuleGenerator < Retrospec::Plugins::V1::Plugin
        attr_reader :template_dir, :context, :module_path, :fact_name, :config_data

        # retrospec will initilalize this class so its up to you
        # to set any additional variables you need to get the job done.
        def initialize(module_path, spec_object = {})
          super
          # below is the Spec Object which serves as a context for template rendering
          # you will need to initialize this object, so the erb templates can get the binding
          # the SpecObject can be customized to your liking as its different for every plugin gem.
          @template_dir = spec_object[:template_dir]
          @context = OpenStruct.new(:module_name => spec_object[:name])
        end

        # used to display subcommand options to the cli
        # the global options are passed in for your usage
        # http://trollop.rubyforge.org
        # all options here are available in the config passed into config object
        # returns a new instance of this class
        def self.run_cli(global_opts)
          namespace     = global_opts['plugins::puppet::namespace'] || 'namespace'
          author        = global_opts['plugins::puppet::author'] || 'author_name'
          sub_command_opts = Trollop.options do
            banner <<-EOS
Generates a new module with the given name and namespace

            EOS
            opt :name, 'The name of the module you wish to create', :type => :string, :required => false, :short => '-n',
                                                                    :default => File.basename(global_opts[:module_path])
            opt :namespace, 'The namespace to use only when creating a new module', :default => namespace, :required => false,
                                                                                    :type => :string
            opt :author, 'The full name of the module author', :default => author, :required => false, :short => '-a',
                                                               :type => :string
          end
          unless sub_command_opts[:name]
            Trollop.educate
            exit 1
          end
          plugin_data = global_opts.merge(sub_command_opts)
          Retrospec::Puppet::Generators::ModuleGenerator.new(plugin_data[:module_path], plugin_data)
        end

        def run(manifest_dir)
          unless File.exist?(manifest_dir)
            init_class = File.join(manifest_dir, 'init.pp')
            content = File.read(File.join(template_dir, 'manifest_file.pp'))
            unless ENV['RETROSPEC_PUPPET_AUTO_GENERATE'] == 'true'
              print "The module located at: #{module_path} does not exist, do you wish to create it? (y/n): "
              answer = gets.chomp
              exit 1 unless answer =~ /y/i
            end

            create_manifest_file(init_class, content)
            generate_metadata_file(config_data[:name], config_data)
          end
        end

        def create_manifest_file(dest, content)
          # replace the name in the target file with the module_name from this class
          # I would have just used a template but the context does not exist yet
          new_content = content.gsub('CLASS_NAME', config_data[:name])
          safe_create_file(dest, new_content)
        end

        def self.generate_metadata_file(mod_name, config_data)
          f = Retrospec::Puppet::Generators::ModuleGenerator.new(config_data[:module_path], config_data)
          f.generate_metadata_file(mod_name, config_data)
        end

        # generates the metadata file in the module directory
        def generate_metadata_file(mod_name, config_data)
          require 'puppet/module_tool/metadata'
          # make sure the metadata file exists
          module_path = config_data[:module_path]
          author = config_data[:author] || config_data['plugins::puppet::author'] || 'your_name'
          namespace = config_data[:namespace] || config_data['plugins::puppet::namespace'] || 'namespace'
          metadata_file = File.join(module_path, 'metadata.json')
          unless File.exist?(metadata_file)
            # by default the module tool metadata checks for a namespece
            if !mod_name.include?('-')
              name = "#{namespace}-#{mod_name}"
            else
              name = mod_name
            end
            begin
              metadata = ::Puppet::ModuleTool::Metadata.new.update(
                'name' => name.downcase,
                'version' => '0.1.0',
                'author'  => author,
                'dependencies' => [
                  { 'name' => 'puppetlabs-stdlib', 'version_requirement' => '>= 4.9.0' }
                ]
              )
            rescue ArgumentError => e
              puts e.message
              exit -1
            end
            safe_create_file(metadata_file, metadata.to_json)
          end
        end
      end
    end
  end
end
