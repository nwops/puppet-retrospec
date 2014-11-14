require 'erb'
require 'puppet'
require 'helpers'
require 'fileutils'

class Retrospec
  attr_reader :included_declarations
  attr_reader :module_path
  attr_reader :tmp_module_path
  attr_accessor :default_modules
  attr_accessor :facts_used

  # module path is the relative or absolute path to the module that should retro fitted
  def initialize(path=nil, default_template_dir=ENV['RETROSPEC_TEMPLATES_PATH'])
    # user supplied a template path or user wants to use local templates
    if not default_template_dir.nil? or ENV['RETROSPEC_ENABLE_LOCAL_TEMPLATES'] =~ /true/i
      default_template_dir = Helpers.setup_user_template_dir(default_template_dir)
    end
    @module_path = validate_module_dir(path)
    @template_dir = default_template_dir
    tmp_module_path
  end

  def default_modules
    @default_modules ||= ['stdlib']
  end

  def create_files
    safe_create_spec_helper
    safe_create_fixtures_file
    safe_create_gemfile
    safe_create_rakefile
    safe_make_shared_context
    types.each do |type|
      safe_create_resource_spec_files(type)
    end
    FileUtils.remove_entry_secure tmp_modules_dir  # ensure we remove the temporary directory
    true
  end

  def safe_create_rakefile(template='rakefile.erb')
    safe_create_template_file('Rakefile', template)
  end

  def safe_make_shared_context(template='shared_context.erb')
    safe_create_template_file(File.join('spec','shared_contexts.rb'), template)
  end

  def safe_create_fixtures_file(template='fixtures_file.erb')
    safe_create_template_file('.fixtures.yml', template)
  end

  def safe_create_spec_helper(template='spec_helper_file.erb')
    safe_create_template_file(File.join('spec','spec_helper.rb'), template)
  end

  def safe_create_gemfile(template='gemfile.erb')
    safe_create_template_file('Gemfile', template)
  end

  def safe_create_template_file(path, template)
    # check to ensure parent directory exists
    file_dir_path = File.expand_path(File.join(module_path,File.dirname(path)))
    if ! File.exists?(file_dir_path)
      Helpers.safe_mkdir(file_dir_path)
    end
    template_path = File.join(template_dir, template)
    File.open(template_path) do |file|
      renderer = ERB.new(file.read, 0, '-')
      content = renderer.result binding
      dest_path = File.expand_path(File.join(module_path,path))
      Helpers.safe_create_file(dest_path, content)
    end
  end

  def types
    @types ||= search_module || []
  end

  # puts a symlink in that module directory that points back to the user supplied module path
  def tmp_module_path
    if @tmp_module_path.nil?
      # create a link where source is the current repo and dest is /tmp/modules/module_name
      path = File.join(tmp_modules_dir, module_name)
      FileUtils.ln_s(module_path, path)
      @tmp_module_path = path
    end
    @tmp_module_path
  end

  def module_name
    @module_name ||= File.basename(module_path)
  end

  # creates a tmp module directory so puppet can work correctly
  def tmp_modules_dir
    if @modules_dir.nil?
      dir = Dir.mktmpdir
      tmp_modules_path = File.expand_path(File.join(dir, 'modules'))
      FileUtils.mkdir_p(tmp_modules_path)
      @modules_dir = tmp_modules_path
    end
    @modules_dir
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

  # processes a directory and expands to its full path, assumes './'
  # returns the validated dir
  def validate_module_dir(dir)
    # first check to see if manifests directory even exists when path is nil
    if dir.nil?
      dir = '.'
    elsif dir.instance_of?(Array)
      raise "Retrospec - an array of moudule paths is not supported at this time"
    end
    dir = File.expand_path(dir)
    manifest_dir = File.join(dir,'manifests')
    if ! File.exist?(manifest_dir)
      raise "No manifest directory in #{manifest_dir}, cannot validate this is a module"
    else
      files = Dir.glob("#{manifest_dir}/**/*.pp")
      warn 'No puppet manifest files found at #' if files.length < 1
    end
    dir
  end

  # finds all the included resources so we can test and depend on in the fixtures file
  # def included_declarations(file)
  #   @included_declarations = {}
  #   includes = []
  #   p = Puppet::Parser::Lexer.new
  #   p.string = File.read(file)
  #   tokens = p.fullscan
  #   k = 0
  #   typename = nil
  #   tokens.each do | token|
  #     next if not token.last.is_a?(Hash)
  #     if typename.nil? and [:CLASS, :DEFINE].include? token.first
  #       j = tokens.index { |token| [:NAME].include? token.first }
  #       typename = tokens[j].last[:value]
  #     end
  #     if token.last.fetch(:value, nil) == 'include'
  #       key = token.last[:value]
  #       value = tokens[k + 1].last[:value]
  #       includes << value
  #     end
  #     k = k + 1
  #   end
  #   @included_declarations[typename] = includes
  #   @included_declarations
  # end

  # Creates an associated spec file for each type and even creates the subfolders for nested classes one::two::three
  def safe_create_resource_spec_files(type,template='resource_spec_file.erb')
    classes_dir = 'spec/classes'
    defines_dir = 'spec/defines'
    hosts_dir   = 'spec/hosts'
    @parameters = type.arguments
    @type = type
    case type.type
      when :hostclass
        type_dir_name = classes_dir
      when :definition
        type_dir_name = defines_dir
      else
        raise "#{type.type} is not a supported resource type yet"
    end
    tokens = type.name.split('::')
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

  def request(key, method)
    instance = Puppet::Indirector::Indirection.instance(:resource_type)
    indirection_name = 'test'
    @request = Puppet::Indirector::Request.new(indirection_name, method, key, instance)
    @request.environment = puppet_environment
    @request
  end

  def resource_type_parser
    @resource_type_parser ||= Puppet::Indirector::ResourceType::Parser.new
  end

  # creates a puppet environment given a module path and environment name
  def puppet_environment
    @puppet_environment ||= Puppet::Node::Environment.create('production', [tmp_modules_dir])
  end

  # returns the resource type ofject given a resource name ie. tomcat::connector
  def find_resource(resource_name)
    request = request(resource_name, 'find')
    resource_type_parser.find(request)
  end

  # returns the resource types found in the module
  def search_module(pattern='*')
    request = request(pattern, 'search')
    resource_type_parser.search(request)
  end

end
