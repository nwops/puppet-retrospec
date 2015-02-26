require 'singleton'

module Utilities
  class PuppetModule
    attr_writer :module_path

    include Singleton

    def self.tmp_module_path
      Utilities::PuppetModule.instance.tmp_module_path
    end

    def self.tmp_modules_dir
      Utilities::PuppetModule.instance.tmp_modules_dir
    end

    def self.module_path
      Utilities::PuppetModule.instance.module_path
    end

    def self.module_name
      Utilities::PuppetModule.instance.module_name
    end

    def self.module_dir_name
      Utilities::PuppetModule.instance.module_dir_name
    end

    def self.module_types
      Utilities::PuppetModule.instance.types
    end

    # create the temporary module create, validate the
    def self.create_tmp_module_path
      Utilities::PuppetModule::instance.create_tmp_module_path(module_path)
    end

    def self.clean_tmp_modules_dir
      FileUtils.remove_entry_secure instance.tmp_modules_dir  # ensure we remove the temporary directory
    end

    def module_path
      @module_path
    end

    # validate and set the module path
    def module_path=(path)
      @module_path = validate_module_dir(path)
    end

    # gets an instance of the module class.  The create_tmp_module_path must first be called
    # before instance can do anything useful.
    def self.instance
      @@instance ||= new
    end

    # processes a directory and expands to its full path, assumes './'
    # returns the validated dir
    def validate_module_dir(dir)
      # first check to see if manifests directory even exists when path is nil
      if dir.nil?
        dir = '.'
      elsif dir.instance_of?(Array)
        puts "Retrospec - an array of module paths is not supported at this time"
        exit 1
      end
      dir = File.expand_path(dir)
      manifest_dir = File.join(dir,'manifests')
      if ! File.exist?(manifest_dir)
        puts "No manifest directory in #{manifest_dir}, cannot validate this is a module"
        exit 1
      else
        files = Dir.glob("#{manifest_dir}/**/*.pp")
        warn "No puppet manifest files found at #{manifest_dir}" if files.length < 1
      end
      dir
    end

    # puts a symlink in that module directory that points back to the user supplied module path
    def create_tmp_module_path(module_path)
      raise "ModulePathNotFound" unless module_path
      path = File.join(tmp_modules_dir, module_dir_name)
      unless File.exists?(path) # only create if it doesn't already exist
        # create a link where source is the current repo and dest is /tmp/modules/module_name
        FileUtils.ln_s(module_path, path)
      end
      path
    end

    def tmp_module_path
      @tmp_module_path ||= File.join(tmp_modules_dir, module_dir_name)
    end

    # the directory name of the module
    # usually this is the same as the module name but it can be namespaced sometimes
    def module_dir_name
      raise "ModulePathNotFound" unless module_path
      @module_dir_name ||= File.basename(module_path)
    end

    def module_type_names
      types.map {|x| x.name}
    end

    # returns the name of the module  ie. mysql::config  => mysql
    def module_name
      begin
        @module_name ||= types.first.name.split('::').first
      rescue
        @module_name = module_dir_name
      end
    end

    # creates a tmp module directory so puppet can work correctly
    def tmp_modules_dir
      if @tmp_modules_dir.nil? or not File.exists?(@tmp_modules_dir)
        dir = Dir.mktmpdir
        tmp_path = File.expand_path(File.join(dir, 'modules'))
        FileUtils.mkdir_p(tmp_path)
        @tmp_modules_dir = tmp_path
      end
      @tmp_modules_dir
    end


    # creates a puppet environment given a module path and environment name
    def puppet_environment
      @puppet_environment ||= Puppet::Node::Environment.create('production', [tmp_modules_dir])
    end

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

    # returns the resource type object given a resource name ie. tomcat::connector
    def find_resource(resource_name)
      request = request(resource_name, 'find')
      resource_type_parser.find(request)
    end

    # returns the resource types found in the module
    def search_module(pattern='*')
      request = request(pattern, 'search')
      resource_type_parser.search(request)
    end

    # TODO we need to parse the types and find all the types that inherit other types and then order them so we can load the files first
    def types
      @types ||= search_module || []
    end
  end
end

