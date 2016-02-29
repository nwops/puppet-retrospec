require_relative 'resource_base_generator'
require_relative 'serializers/rspec_dumper'
require 'puppet'
require 'puppet/pops'

module Retrospec
  module Puppet
    module Generators
      class AcceptanceGenerator < Retrospec::Puppet::Generators::ResourceBaseGenerator
        # retrospec will initilalize this class so its up to you
        # to set any additional variables you need to get the job done.
        def initialize(module_path, spec_object = {})
          super
          @singular_name = 'acceptance'
          @plural_name = 'acceptance'
        end

        def spec_template_file
          'acceptance_spec_test.rb.retrospec.erb'
        end

        def self.generate_spec_files(module_path)
          files = []
          manifest_files(module_path).each do |file|
            acceptance = new(module_path, {:manifest_file => file})
            files << acceptance.generate_spec_file
          end
          files
        end

      end

    end
  end
end
