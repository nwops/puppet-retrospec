module Retrospec
  module Puppet
    module Generators
      class BaseGenerator < Retrospec::Plugins::V1::Plugin
        attr_reader :template_dir, :generator_template_dir_name, :plural_name, :singular_name
        attr_accessor :context
        # retrospec will initilalize this class so its up to you
        # to set any additional variables you need to get the job done.
        def initialize(module_path, spec_object = {})
          super
          # below is the Spec Object which serves as a context for template rendering
          # you will need to initialize this object, so the erb templates can get the binding
          # the SpecObject can be customized to your liking as its different for every plugin gem.
          @context = OpenStruct.new(spec_object)
        end

        def logger
          Retrospec::Plugins::V1::Puppet.logger
        end

        # used to display subcommand options to the cli
        # the global options are passed in for your usage
        # http://optimist.rubyforge.org
        # all options here are available in the config passed into config object
        # returns the parameters
        def self.run_cli(global_opts, args=ARGV)
          sub_command_opts = Optimist.options(args) do
            banner <<-EOS
            ""
            EOS
            opt :name, "The name of the item you wish to create", :type => :string, :required => true, :short => '-n'
          end
          unless sub_command_opts[:name]
            Optimist.educate
            exit 1
          end
          plugin_data = global_opts.merge(sub_command_opts)
          plugin_data
        end

        def generate_lib_files
          raise NotImplementedError
        end

        def generate_spec_files
          raise NotImplementedError
        end

        # generates a file path for spec tests based on the resource name.  An added option
        # is to generate directory names for each parent resource as a default option
        def item_spec_path
          file_name = generate_file_name(item_name.downcase)
          path = generate_path("#{file_name}_spec.rb", item_name)
          File.join(spec_path, path )
        end

        # returns the base filename of the type
        def generate_file_name(iname)
          tokens = iname.split('::')
          file_name = tokens.pop
        end

        # @return [String] - a generated path
        # @param file_name - the base name of the file to create
        # @param iname - the type name or name of item
        def generate_path(file_name, iname = item_name)
          tokens = iname.split('::')
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
            dir_name = File.join(dir_name, file_name) # spec/classes/tomcat/config/server
          else
            dir_name = File.join(file_name)
          end
          dir_name.downcase
        end

        # run is the main method that gets called automatically
        def run
          generate_lib_files
        end

        def item_name
          context.name
        end

        def item_path
          File.join(lib_path, "#{item_name}.rb")
        end

        def spec_path
          File.join(module_path, 'spec', 'unit', 'puppet', plural_name)
        end

        def lib_path
          File.join(module_path, 'lib', 'puppet', plural_name)
        end

        # returns the path to the templates
        # first looks inside the external templates directory for specific file
        # then looks inside the gem path templates directory, which is really only useful
        # when developing new templates.
        def template_dir
          if config_data[:template_dir]
            external_templates = Dir.glob(File.expand_path(File.join(config_data[:template_dir], plural_name, '*.erb')))
          end
          if external_templates and external_templates.count > 0
            File.join(config_data[:template_dir], plural_name)
          else
            File.expand_path(File.join(File.dirname(File.dirname(__FILE__)), 'templates', plural_name))
          end
        end

        def get_binding
          binding
        end
      end
    end
  end
end
