require_relative 'base_generator'

module Retrospec
  module Puppet
    module Generators
      class ReportGenerator < Retrospec::Puppet::Generators::BaseGenerator
        # retrospec will initilalize this class so its up to you
        # to set any additional variables you need to get the job done.
        def initialize(module_path, spec_object = {})
          super
          @plural_name = 'reports'
          @singular_name = 'report'
        end

        def run
          files = []
          files << generate_lib_files
          files << generate_spec_files
          files
        end

        def generate_lib_files
          template_file = File.join(template_dir, 'report.rb.retrospec.erb')
          safe_create_template_file(item_path, template_file, context)
          item_path
        end

        def generate_spec_files
          template_file = File.join(template_dir, 'report_spec.rb.retrospec.erb')
          safe_create_template_file(item_spec_path, template_file, context)
          item_spec_path
        end

        # used to display subcommand options to the cli
        # the global options are passed in for your usage
        # http://trollop.rubyforge.org
        # all options here are available in the config passed into config object
        # returns the parameters
        def self.run_cli(global_opts, args=ARGV)
          sub_command_opts = Trollop.options(args) do
            banner <<-EOS
Creates a new puppet report
            EOS
            opt :name, "The name of the report you wish to create", :type => :string, :required => true, :short => '-n'
          end
          unless sub_command_opts[:name]
            Trollop.educate
            exit 1
          end
          plugin_data = global_opts.merge(sub_command_opts)
          plugin_data
        end
      end
    end
  end
end
