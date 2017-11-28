require 'retrospec'
module Retrospec
  module Puppet
    module TemplateHelpers

      # @note creates the user supplied or default template directory
      # @return [String] - user_template_dir
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

      # @note creates and/or copies all templates in the gem to the user templates path
      # @return [String] - user_template_dir
      def sync_user_template_dir(user_template_directory)
        Dir.glob(File.join(gem_template_dir, '**', '{*,.*}')).each do |src|
          dest = src.gsub(gem_template_dir, user_template_directory)
          safe_copy_file(src, dest) unless File.directory?(src)
        end
        user_template_directory
      end

      # @note creates and syncs the specifed user template diretory
      # @return [String] - user_template_dir
      def setup_user_template_dir(user_template_directory = nil, git_url = nil, branch = nil)
        if user_template_directory.nil?
          user_template_directory = default_user_template_dir
        end
        template_dir = create_user_template_dir(user_template_directory)
        run_clone_hook(user_template_directory, git_url, branch)
        template_dir
      end

      # @return [String] - the default retrospec templates directory
      def default_user_template_dir
        File.expand_path(File.join(ENV['HOME'], '.retrospec', 'repos', 'retrospec-puppet-templates'))
      end

      # @return [String] - the template directory that exists in this gem on the filesytem
      def gem_template_dir
        File.expand_path(File.join(File.dirname(__FILE__), 'templates'))
      end

      # @return [String] window's specific file path for windows and unix specific path for unix
      # @param [String] path to the template directory
      def clone_hook_file(template_dir)
        hook_file_name = 'clone-hook'
        if File.exist?(File.join(template_dir, hook_file_name))
          hook_file = File.join(template_dir, hook_file_name)
        else
          hook_file = File.join(gem_template_dir, hook_file_name)
        end
        hook_file
      end

      # runs the clone hook file
      # the intention of this method and hook is to download the templates
      # from an external repo. Because templates are updated frequently
      # and users will sometimes have client specific templates I wanted to
      # externalize them for easier management.
      # @param template_dir [String] - the path to the template dir
      # @param git_url [String] - the git url of the template repository
      # @param branch [String] - the branch or ref to use 
      def run_clone_hook(template_dir, git_url = nil, branch = nil)
        hook_file = clone_hook_file(template_dir)
        return unless File.exist?(hook_file)
        output = `ruby #{hook_file} #{template_dir} #{git_url} #{branch}`
        puts output
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
