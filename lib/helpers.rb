require 'fileutils'

class Helpers


  def self.run(module_name=nil)
    unless is_module_dir?
      $stderr.puts "Does not appear to be a Puppet module.  Aborting"
      return false
    end

    if module_name.nil?
      module_name = get_module_name
      if module_name.nil?
        $stderr.puts "Unable to determine module name.  Aborting"
        return false
      end
    end

    [
        'spec',
        'spec/classes',
        'spec/defines',
        'spec/functions',
        'spec/unit', 'spec/unit/facter', 'spec/unit/puppet', 'spec/unit/puppet/type', 'spec/unit/puppet/provider',
        'spec/hosts',
    ].each { |dir| safe_mkdir(dir) }


    safe_create_spec_helper
    safe_create_fixtures_file
    safe_create_resource_spec_files
    safe_make_shared_context
  end

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

  def self.is_module_dir?
    Dir["*"].entries.include? "manifests"
  end

  def self.safe_mkdir(dir)
    if File.exists? dir
      unless File.directory? dir
        $stderr.puts "!! #{dir} already exists and is not a directory"
      end
    else
      FileUtils.mkdir_p dir
      puts " + #{dir}/"
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
    Dir.glob(File.join(gem_template_dir, "*.erb")).each do |src|
      filename = File.basename(src)
      dest = File.expand_path(File.join(user_template_directory, filename))
      safe_copy_file(src, dest)
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
    if File.exists?(dest)
      $stderr.puts "!! #{dest} already exists"
    else
      if not File.exists?(src)
        safe_touch(src)
      else
        FileUtils.cp(src,dest)
      end
      puts " + #{dest}"
    end
  end

  def self.safe_touch(file)
    if File.exists? file
      unless File.file? file
        $stderr.puts "!! #{file} already exists and is not a regular file"
      end
    else
      FileUtils.touch file
      puts " + #{file}"
    end
  end

  def self.safe_create_file(filename, content)
    if File.exists? filename
      old_content = File.read(filename)
      if old_content != content
        $stderr.puts "!! #{filename} already exists and differs from template"
      end
    else
      File.open(filename, 'w') do |f|
        f.puts content
      end
      puts " + #{filename}"
    end
  end
end
