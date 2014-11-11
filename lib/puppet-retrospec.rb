require 'erb'
require 'puppet'
require 'helpers'
require 'fileutils'

class Retrospec
  attr_reader :included_declarations
  attr_reader :classes_and_defines
  attr_reader :module_name
  attr_reader :modules_included
  attr_accessor :default_path
  attr_accessor :manifest_files
  attr_accessor :default_modules
  attr_accessor :template_dir


  def initialize(path=nil, default_template_dir=ENV['RETROSPEC_TEMPLATES_PATH'])
    # user supplied a template path or user wants to use local templates
    if not default_template_dir.nil? or ENV['RETROSPEC_ENABLE_LOCAL_TEMPLATES'] =~ /true/i
      default_template_dir = Helpers.setup_user_template_dir(default_template_dir)
    end
    @default_path = path
    @default_modules = ['stdlib']
    @template_dir = default_template_dir
    module_name
    modules_included
  end

  def create_files
    safe_create_spec_helper
    safe_create_fixtures_file
    safe_create_gemfile
    manifest_files.each do |file|
      safe_create_resource_spec_files(file)
    end
    safe_make_shared_context
  end

  # pass in either the path to the module directory
  # or the path to a specific manifest
  # defaults to all manifests in the current directory
  # if ENV['RETROSPEC_ENABLE_LOCAL_TEMPLATES'] = 'true' the use the default user templates path
  # if ENV["RETROSPEC_TEMPLATES_PATH"] is set then we will override the default user template path
  # with the path provided
  # we will use the necessary templates from that directory instead of the default gem path
  def self.run(path=nil, template_dir=ENV['RETROSPEC_TEMPLATES_PATH'])
    spec = Retrospec.new(path, template_dir)
    spec.create_files
  end

  def safe_create_gemfile(template='gemfile.erb')
    safe_create_template_file('Gemfile', template)
  end

  # if user doesn't supply template directory we assume we should use the templates in this gem
  def template_dir
    @template_dir ||= Helpers.gem_template_dir
  end

  def modules_included
    @modules_included ||= default_modules + referenced_modules
  end

  def referenced_modules
    []
  end

  def module_name
    @module_name ||= Helpers.get_module_name
  end

  def manifest_files
    if @manifest_files.nil?
      # first check to see if manifests directory even exists when path is nil
      if default_path.nil?
        raise 'No manifest directory' if ! File.exist?('manifests')
        @default_path = 'manifests/**/*.pp'
      # check to see if at least one of the files given is a pp file
      # remove any non pp files
      elsif default_path.instance_of?(Array)
         data = default_path.find_all { |file| File.extname(file) == '.pp' }
         if data.length < 1
           raise "No valid puppet manifests given"
         end
         @default_path = data
      # this should be a module directory which would have a manifests directory
      elsif Dir.exist?(File.expand_path(default_path))
        raise 'No manifest directory' if ! File.exist?(File.expand_path(File.join(default_path, 'manifests')))
        @default_path = File.join(default_path, 'manifests/**/*.pp')
      else
        path = File.expand_path(default_path)
        raise "File does not exist at path #{path}" if ! File.exist?(path)
        raise 'Not a puppet manifest file' if File.extname(path) != '.pp'
      end
      @manifest_files = Dir.glob(default_path)

    end
    @manifest_files
  end

  def classes_and_defines(file)
      @classes_and_defines = []
      # for each file we are going to use the puppet lexer to find the class or define
      resources = []
      p = Puppet::Parser::Lexer.new
      p.string = File.read(file)
      tokens = p.fullscan
      tokens.each do | token|
        if [:CLASS, :DEFINE].include? token.first
          k = tokens.index { |token| [:NAME].include? token.first }
          # there is some sort of ordering bug here with ruby 1.8.7 and I have to modify the code like below
          # to get it working. I think its this index method above
          # TODO make this work with ruby versions 1.8.7 and above
          #resources.push({:type_name => tokens[k-1].last[:value], :name => token.last[:value] })
          resources.push({:type_name => token.last[:value] , :name => tokens[k].last[:value] })
        end
      end
      # sometimes the manifest can be blank and not include a class or define statement
      if resources.length > 0
        @classes_and_defines.push({:filename => File.basename(file, '.pp'), :types => resources })
      end
    @classes_and_defines
  end

  # finds all the included resources so we can test and depend on in the fixtures file
  def included_declarations(file)
    @included_declarations = {}
    includes = []
    p = Puppet::Parser::Lexer.new
    p.string = File.read(file)
    tokens = p.fullscan
    k = 0
    typename = nil
    tokens.each do | token|
      next if not token.last.is_a?(Hash)
      if typename.nil? and [:CLASS, :DEFINE].include? token.first
        j = tokens.index { |token| [:NAME].include? token.first }
        typename = tokens[j].last[:value]
      end
      if token.last.fetch(:value, nil) == 'include'
        key = token.last[:value]
        value = tokens[k + 1].last[:value]
        includes << value
      end
      k = k + 1
    end
    @included_declarations[typename] = includes
    @included_declarations
  end


  def safe_make_shared_context(template='shared_context.erb')
    safe_create_template_file('spec/shared_contexts.rb', template)
  end

  # Gets all the classes and define types from all the files in the manifests directory
  # Creates an associated spec file for each type and even creates the subfolders for nested classes one::two::three
  def safe_create_resource_spec_files(manifest_file,template='resource_spec_file.erb')
    classes_dir = 'spec/classes'
    defines_dir = 'spec/defines'
    classes_and_defines(manifest_file).each do |value|
      types = value[:types]
      types.each do |type|
        # run template
        tokens = type[:name].split('::')
        if type[:type_name] == 'class'
          type_dir_name = classes_dir
        else
          type_dir_name = defines_dir
        end
        file_name = tokens.pop  # the last item should be the filename
        # if there are only two tokens ie. tomcat::params we dont need to create a subdirectory
        if tokens.count > 1
          # this is a deep level resource ie. tomcat::config::server::connector
          # however we don't need the tomcat directory so we can just remove it
          # this should leave us with config/server/connector_spec.rb
          tokens.delete_at(0)
          # so lets make a directory structure out of it
          dir_name = File.join(tokens)  # config/server
          dir_name = File.join(type_dir_name,dir_name) # spec/classes/tomcat/config/server
          safe_create_template_file(File.join(dir_name,"#{file_name}_spec.rb"), template)
        else
          safe_create_template_file(File.join(type_dir_name,"#{file_name}_spec.rb"), template)
        end
      end
    end
  end

  def safe_create_fixtures_file(template='fixtures_file.erb')
    safe_create_template_file('.fixtures.yml', template)
  end

  def safe_create_spec_helper(template='spec_helper_file.erb')
    safe_create_template_file('spec/spec_helper.rb', template)
  end

  def safe_create_template_file(path, template)
    # check to ensure parent directory exists
    file_dir_path = File.expand_path(File.join(module_dir,File.dirname(path)))
    if ! File.exists?(file_dir_path)
      Helpers.safe_mkdir(file_dir_path)
    end
    template_path = File.join(template_dir, template)
    File.open(template_path) do |file|
      renderer = ERB.new(file.read, 0, '>')
      content = renderer.result binding
      Helpers.safe_create_file(File.expand_path(File.join(module_dir,path)), content)
    end

  end

  # calculates where the spec directory is by going one directory back from manifests directory
  def module_dir
    @spec_dir ||= File.join(File.dirname(manifest_dir))
  end

  def manifest_dir
    # look and compare, then get basename, loop till found
    if @manifest_dir.nil?
      file = manifest_files.first
      file.split(File::SEPARATOR).each do |part|
        filename = File.basename(file)
        if filename != 'manifests'
          file = File.dirname(file)
        else
          @manifest_dir = file
        end
      end
    end
    @manifest_dir
  end

end
