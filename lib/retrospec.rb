require 'erb'
require 'puppet'
require 'retrospec/helpers'
require 'fileutils'
require 'retrospec/resource'
require 'retrospec/conditional'
require 'retrospec/variable_store'

class Retrospec
  attr_reader :module_path
  attr_reader :tmp_module_path
  attr_accessor :module_name
  attr_reader :template_dir

  # module path is the relative or absolute path to the module that should retro fitted
  # opts hash contains additional flags and options that can be user to control the creation of the tests
  # opts[:enable_user_templates]
  # opts[:enable_beaker_tests]
  # opts[:template_dir]
  def initialize(module_path=nil,opts={})
    # user supplied a template path or user wants to use local templates
    if opts[:template_dir] or opts[:enable_user_templates]
      @template_dir = Helpers.setup_user_template_dir(opts[:template_dir])
    else
      # if user doesn't supply template directory we assume we should use the templates in this gem
      @template_dir = Helpers.gem_template_dir
    end
    @enable_beaker_tests = opts[:enable_beaker_tests]
    @module_path = validate_module_dir(module_path)
    tmp_module_path # this is required to finish initialization
  end

  def enable_beaker_tests?
    @enable_beaker_tests == true
  end

  def create_files
    safe_create_spec_helper
    safe_create_fixtures_file
    safe_create_gemfile
    safe_create_rakefile
    safe_make_shared_context
    safe_create_acceptance_spec_helper if enable_beaker_tests?
    safe_create_node_sets if enable_beaker_tests?
    types.each do |type|
      safe_create_resource_spec_files(type)
      if enable_beaker_tests?
        safe_create_acceptance_tests(type)
      end
    end
    FileUtils.remove_entry_secure tmp_modules_dir  # ensure we remove the temporary directory
    true
  end

  def safe_create_node_sets
    # copy all of the nodesets from the templates path nodesets directory
    Dir.glob("#{template_dir}/nodesets/*.yml").each do |node_set_file|
      dest = File.expand_path(File.join(module_path, 'spec', 'acceptance', 'nodesets', File.basename(node_set_file) ))
      Helpers.safe_copy_file(node_set_file,dest)
    end
  end

  def safe_create_acceptance_spec_helper(template='spec_helper_acceptance.rb.erb')
     safe_create_template_file(File.join('spec', 'spec_helper_acceptance.rb'), template)
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
      path = File.join(tmp_modules_dir, module_dir_name)
      FileUtils.ln_s(module_path, path)
      @tmp_module_path = path
    end
    @tmp_module_path
  end

  # the directory name of the module
  # usually this is the same as the module name but it can be namespaced sometimes
  def module_dir_name
    @module_dir_name ||= File.basename(module_path)
  end

  # returns the name of the module  ie. mysql::config  => mysql
  def module_name
    if @module_name.nil?
      @module_name = types.first.name.split('::').first if types.length > 0
    end
    @module_name
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

  # Creates an associated spec file for each type and even creates the subfolders for nested classes one::two::three
  def safe_create_resource_spec_files(type,template='resource_spec_file.erb')
    @parameters = type.arguments
    @type = type
    @resources = Resource.all(type)
    # pass the type to the variable store and it will discover all the variables and try to resolve them.
    VariableStore.populate(type)
    @resources += Conditional.all(type)
    file_path = generate_file_path(type, false)
    safe_create_template_file(file_path, template)
    file_path
  end

  def safe_create_acceptance_tests(type,template='acceptance_spec_test.erb')
    @parameters = type.arguments
    @type = type
    file_path = generate_file_path(type, true)
    safe_create_template_file(file_path, template)
    file_path
  end

  # creates a puppet environment given a module path and environment name
  def puppet_environment
    @puppet_environment ||= Puppet::Node::Environment.create('production', [tmp_modules_dir])
  end

  # generates a file path for spec tests based on the resource name.  An added option
  # is to generate directory names for each parent resource as a default option
  # at this time acceptance tests follow this same test directory layout until best
  # practices are formed.
  def generate_file_path(type, is_acceptance_test)
    classes_dir = 'classes'
    defines_dir = 'defines'
    hosts_dir   = 'hosts'
    acceptance_dir = 'acceptance'
    case type.type
      when :hostclass
        type_dir_name = classes_dir
      when :definition
        type_dir_name = defines_dir
      else
        raise "#{type.type} retrospec does not support this resource type yet"
    end
    if is_acceptance_test
      type_dir_name = File.join('spec',acceptance_dir, type_dir_name)
    else
      type_dir_name = File.join('spec', type_dir_name)
    end
    file_name = generate_file_name(type.name)
    tokens = type.name.split('::')
    # if there are only two tokens ie. tomcat::params we dont need to create a subdirectory
    if tokens.count > 1
      # this is a deep level resource ie. tomcat::config::server::connector
      # however we don't need the tomcat directory so we can just remove it
      # this should leave us with config/server/connector_spec.rb
      tokens.delete_at(0)
      # so lets make a directory structure out of it
      dir_name = File.join(tokens)  # config/server
      dir_name = File.join(type_dir_name,dir_name, file_name) # spec/classes/tomcat/config/server
    else
      dir_name = File.join(type_dir_name,file_name)
    end
    dir_name
  end

  # returns the filename of the type
  def generate_file_name(type_name)
    tokens = type_name.split('::')
    file_name = tokens.pop
    "#{file_name}_spec.rb"
  end

  private

  # creates a puppet resource request to be used indirectly
  def request(key, method)
    instance = Puppet::Indirector::Indirection.instance(:resource_type)
    indirection_name = 'test'
    @request = Puppet::Indirector::Request.new(indirection_name, method, key, instance)
    @request.environment = puppet_environment
    @request
  end

  # creates an instance of the resource type parser
  def resource_type_parser
    @resource_type_parser ||= Puppet::Indirector::ResourceType::Parser.new
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
end
