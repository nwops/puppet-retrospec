module PuppetModule
    module Utilities

      # puts a symlink in that module directory that points back to the user supplied module path
      def create_tmp_module_path(module_path)
        path = File.join(tmp_modules_dir, module_dir_name)
        unless File.exists?(path)
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
        @module_dir_name ||= File.basename(module_path)
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
        if @tmp_modules_dir.nil?
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
