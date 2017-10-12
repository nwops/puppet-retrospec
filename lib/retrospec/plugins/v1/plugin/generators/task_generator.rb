require 'json'

module Retrospec
  module Puppet
    module Generators
      class TaskGenerator < Retrospec::Puppet::Generators::BaseGenerator
        EXT_TYPES = {
            'ruby' => 'rb',
            'generic' => 'generic',
            'python' => 'py',
            'powershell' => 'ps1',
            'bash' => 'sh',
            'node' => 'js'
        }

        # retrospec will initilalize this class so its up to you
        # to set any additional variables you need to get the job done.
        def initialize(module_path, spec_object = {})
          super
          @plural_name = 'tasks'
          @singular_name = 'task'
        end

        def shebang
          "#!/usr/bin/env #{task_type}"
        end

        def task_params
          config_data[:task_params].gsub(/\s/, '').split(",")
        end

        def task_params_output
          params = {}
          task_params.each_with_object({}) do |item, obj|
            obj["description"] = "The description of the #{item} parameter"
            obj["type"] = "String"
            params[item] = obj
          end
          params
        end

        def task_type
          config_data[:task_type]
        end

        def run
          files = []
          files << generate_task_files
          files
        end

        def task_filepath
          ext = EXT_TYPES.fetch(task_type, task_type)
          File.join(module_path, 'tasks', "#{item_name}.#{ext}")
        end

        def task_params_filepath
          File.join(module_path, 'tasks', "#{item_name}.json")
        end

        def item_spec_path
          File.join(spec_path, plural_name, "#{item_name}_spec.rb")
        end

        def enable_beaker_tasks?
          false
        end

        def generate_task_files
          context.task_type = task_type
          context.shebang = shebang
          context.task_params_output = task_params_output
          context.task_params = task_params
          parameter_template = File.join(template_dir, 'task_parameters.json.retrospec.erb')
          task_template = Dir.glob(File.join(template_dir, 'types', task_type, '*')).first
          unless task_template
            task_template = Dir.glob(File.join(template_dir, 'types', 'task.retrospec.erb')).first
          end
          files = []
          files << safe_create_template_file(task_filepath, task_template, context)
          files << safe_create_template_file(task_params_filepath, parameter_template, context)
          files
        end

        # used to display subcommand options to the cli
        # the global options are passed in for your usage
        # http://trollop.rubyforge.org
        # all options here are available in the config passed into config object
        # returns the parameters
        def self.run_cli(global_opts, args=ARGV)
          task_types = %w(bash generic ruby python node powershell)
          task_type  = global_opts['plugins::puppet::default_task_type'] || 'bash'
          sub_command_opts = Trollop.options(args) do
            banner <<-EOS
Creates a new puppet bolt task for your module

Example: retrospec puppet new_task -n reboot -p "name, ttl, message"

            EOS
            opt :name, "The name of the task you wish to create", :type => :string, :required => true, :short => '-n'
            opt :task_params, "The task parameter names separated by commas", :short => '-p', :type => :string, :required => false, default: "name"
            opt :task_type, "The task type of the task (#{task_types.join(', ')})", :type => :string, :required => false, :short => '-t',
                :default => task_type

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
