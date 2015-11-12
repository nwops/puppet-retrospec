require 'retrospec'
module Retrospec
  module Puppet
    module TemplateHelpers
      # creates the user supplied or default template directory
      # returns: user_template_dir
      def create_user_template_dir(user_template_directory = nil)
        if user_template_directory.nil?
          user_template_directory = default_user_template_dir
        end
        # create default user template path or supplied user template path
        unless File.exist?(user_template_directory)
          FileUtils.mkdir_p(File.expand_path(user_template_directory))
        end
        user_template_directory
      end

      # creates and/or copies all templates in the gem to the user templates path
      # returns: user_template_dir
      def sync_user_template_dir(user_template_directory)
        Dir.glob(File.join(gem_template_dir, '**', '{*,.*}')).each do |src|
          dest = src.gsub(gem_template_dir, user_template_directory)
          safe_copy_file(src, dest) unless File.directory?(src)
        end
        user_template_directory
      end

      # creates and syncs the specifed user template diretory
      # returns: user_template_dir
      def setup_user_template_dir(user_template_directory = nil, git_url = nil, branch = nil)
        if user_template_directory.nil?
          user_template_directory = default_user_template_dir
        end
        template_dir = create_user_template_dir(user_template_directory)
        run_clone_hook(user_template_directory, git_url, branch)
        template_dir
      end

      def default_user_template_dir
        File.expand_path(File.join(ENV['HOME'], '.retrospec', 'repos', 'retrospec-puppet-templates'))
      end

      def gem_template_dir
        File.expand_path(File.join(File.dirname(__FILE__), 'templates'))
      end

      # runs the clone hook file
      # the intention of this method and hook is to download the templates
      # from an external repo. Because templates are updated frequently
      # and users will sometimes have client specific templates I wanted to
      # externalize them for easier management.
      def run_clone_hook(template_dir, git_url = nil, branch = nil)
        if File.exist?(File.join(template_dir, 'clone-hook'))
          hook_file = File.join(template_dir, 'clone-hook')
        else
          hook_file = File.join(gem_template_dir, 'clone-hook')
        end
        if File.exist?(hook_file)
          output = `#{hook_file} #{template_dir} #{git_url} #{branch}`
          if $CHILD_STATUS.success?
            puts "Successfully ran hook: #{hook_file}".info
            puts output.info
          else
            puts "Error running hook: #{hook_file}".fatal
            puts output.fatal
          end
        end
      end
    end
  end
end
