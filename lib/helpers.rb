
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
    safe_create_rakefile
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
