require 'fileutils'

class Helpers

  def self.get_module_name
    module_name = nil
    Dir["manifests/*.pp"].entries.each do |manifest|
      module_name = get_module_name_from_file(manifest)
      break unless module_name.nil?
    end
    module_name
  end

  def self.get_module_name_from_file(file)
    p = Puppet::Parser::Lexer.new
    module_name = nil
    p.string = File.read(file)
    tokens = p.fullscan

    i = tokens.index { |token| [:CLASS, :DEFINE].include? token.first }
    unless i.nil?
      module_name = tokens[i + 1].last[:value].split('::').first
    end

    module_name
  end

  def self.is_module_dir?(dir)
    Dir[File.join(dir,"*")].entries.include? "manifests"
  end

  def self.safe_mkdir(dir)
    if File.exists? dir
      unless File.directory? dir
        $stderr.puts "!! #{dir} already exists and is not a directory".fatal
      end
    else
      FileUtils.mkdir_p dir
      puts " + #{dir}/".info
    end
  end

  # creates the user supplied or default template directory
  # returns: user_template_dir
  def self.create_user_template_dir(user_template_directory=nil)
    if user_template_directory.nil?
      user_template_directory = default_user_template_dir
    end
    # create default user template path or supplied user template path
    if not File.exists?(user_template_directory)
      FileUtils.mkdir_p(File.expand_path(user_template_directory))
    end
    user_template_directory
  end

  # creates and/or copies all templates in the gem to the user templates path
  # returns: user_template_dir
  def self.sync_user_template_dir(user_template_directory)
    Dir.glob(File.join(gem_template_dir, '**', '*')).each do |src|
      dest = src.gsub(gem_template_dir, user_template_directory)
      safe_copy_file(src, dest) unless File.directory?(src)
    end
    user_template_directory
  end

  # creates and syncs the specifed user template diretory
  # returns: user_template_dir
  def self.setup_user_template_dir(user_template_directory=nil)
    if user_template_directory.nil?
      user_template_directory = default_user_template_dir
    end
    sync_user_template_dir(create_user_template_dir(user_template_directory))
  end

  def self.default_user_template_dir
    File.expand_path(File.join(ENV['HOME'], '.puppet_retrospec_templates' ))
  end

  def self.gem_template_dir
    File.expand_path(File.join(File.dirname(__FILE__), 'templates'))
  end

  def self.safe_copy_file(src, dest)
    if File.exists?(dest) and not File.zero?(dest)
      $stderr.puts "!! #{dest} already exists".warning
    else
      if not File.exists?(src)
        safe_touch(src)
      else
        safe_mkdir(File.dirname(dest))
        FileUtils.cp(src,dest)
      end
      puts " + #{dest}".info
    end
  end

  def self.safe_touch(file)
    if File.exists? file
      unless File.file? file
        $stderr.puts "!! #{file} already exists and is not a regular file".fatal
      end
    else
      FileUtils.touch file
      puts " + #{file}".info
    end
  end

  def self.safe_create_file(filepath, content)
    if File.exists? filepath
      old_content = File.read(filepath)
      # if we did a better comparison of content we could be smarter about when we create files
      if old_content != content or not File.zero?(filepath)
        $stderr.puts "!! #{filepath} already exists and differs from template".warning
      end
    else
      safe_mkdir(File.dirname(filepath)) unless File.exists? File.dirname(filepath)
      File.open(filepath, 'w') do |f|
        f.puts content
      end
      puts " + #{filepath}".info
    end
  end
end
