require 'erb'
require 'puppet'
require 'retrospec/helpers'
require 'fileutils'
require 'retrospec/resource'
require 'retrospec/conditional'
require 'retrospec/variable_store'
require 'retrospec/puppet_module'
require 'retrospec/spec_object'
require 'retrospec/exceptions'
require 'retrospec/version'

class Retrospec

  attr_reader :template_dir
  attr_reader :module_path
  attr_reader :spec_object

  # module path is the relative or absolute path to the module that should retro fitted
  # opts hash contains additional flags and options that can be user to control the creation of the tests
  # opts[:enable_user_templates]
  # opts[:enable_beaker_tests]
  # opts[:template_dir]
  def initialize(supplied_module_path=nil,opts={})
    Utilities::PuppetModule.instance.future_parser = opts[:enable_future_parser]
    # user supplied a template path or user wants to use local templates
    if opts[:template_dir] or opts[:enable_user_templates]
      @template_dir = Helpers.setup_user_template_dir(opts[:template_dir])
    else
      # if user doesn't supply template directory we assume we should use the templates in this gem
      @template_dir = Helpers.gem_template_dir
    end
    begin
      Utilities::PuppetModule.instance.module_path = supplied_module_path
      Utilities::PuppetModule.create_tmp_module_path # this is required to finish initialization
      @module_path = Utilities::PuppetModule.module_path
      @spec_object = Utilities::SpecObject.new(Utilities::PuppetModule.instance)
      spec_object.enable_beaker_tests = opts[:enable_beaker_tests]
    end
  end

  def create_files
    safe_create_module_files
    # a Type is nothing more than a defined type or puppet class
    # we could have named this manifest but there could be multiple types
    # in a manifest.
    spec_object.types.each do |type|
       safe_create_resource_spec_files(type)
       if spec_object.enable_beaker_tests?
         safe_create_acceptance_tests(type)
       end
    end
    Utilities::PuppetModule.clean_tmp_modules_dir
    true
  end

  # creates any file that is contained in the templates/modules_files directory structure
  # loops through the directory looking for erb files, all other files are ignored.
  # strips the erb extension and renders the template to the current module path
  # filenames must named how they would appear in the normal module path.  The directory
  # structure where the file is contained
  def safe_create_module_files
    templates = Dir.glob(File.join(template_dir,'module_files', '**', '{*,.*}')).find_all {|t| File.file?(t)}
    templates.each do |template|
      # need to remove the erb extension and rework the destination path
      if template =~ /nodesets|spec_helper_acceptance/ and !spec_object.enable_beaker_tests?
        next
      else
        dest = template.gsub(File.join(template_dir,'module_files'), module_path).gsub('.erb', '')
        safe_create_template_file(dest, template)
      end
    end
  end

  # path is the full path of the file to create
  # template is the full path to the template file
  def safe_create_template_file(path, template)
    # check to ensure parent directory exists
    file_dir_path = File.expand_path(File.dirname(path))
    if ! File.exists?(file_dir_path)
      Helpers.safe_mkdir(file_dir_path)
    end
    File.open(template) do |file|
      renderer = ERB.new(file.read, 0, '-')
      content = renderer.result spec_object.get_binding
      dest_path = File.expand_path(path)
      Helpers.safe_create_file(dest_path, content)
    end
  end

  # Creates an associated spec file for each type and even creates the subfolders for nested classes one::two::three
  def safe_create_resource_spec_files(type,template=File.join(template_dir,'resource_spec_file.erb'))
    spec_object.parameters = type.arguments
    spec_object.type = type
    VariableStore.populate(type)
    spec_object.resources = Resource.all(type)
    # pass the type to the variable store and it will discover all the variables and try to resolve them.
    # this does not get deep nested conditional blocks
    spec_object.resources += Conditional.all(type)
    file_path = File.join(module_path,generate_file_path(type, false))
    safe_create_template_file(file_path, template)
    file_path
  end

  def safe_create_acceptance_tests(type,template=File.join(template_dir,'acceptance_spec_test.erb'))
    @parameters = type.arguments
    @type = type
    file_path = File.join(module_path,generate_file_path(type, true))
    safe_create_template_file(file_path, template)
    file_path
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
    if tokens.count > 2
      # this is a deep level resource ie. tomcat::config::server::connector
      # however we don't need the tomcat directory so we can just remove it
      # this should leave us with config/server/connector_spec.rb
      tokens.delete_at(0)
      # remove the last token since its the class name
      tokens.pop
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
end

class String
  def red;            "\033[31m#{self}\033[0m" end
  def green;          "\033[32m#{self}\033[0m" end
  def cyan;           "\033[36m#{self}\033[0m" end
  def yellow;         "\033[33m#{self}\033[0m" end
  def warning;        yellow                   end
  def fatal;          red                      end
  def info;           green                    end
end