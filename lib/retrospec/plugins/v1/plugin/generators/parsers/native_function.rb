require_relative '../serializers/rspec_dumper'
require 'ostruct'
module Parsers
  class NativeFunction
    attr_reader :manifest_file

    def initialize(file)
      @manifest_file = file
    end

    # @param [String] - path to the function file
    # @return [OpenStruct] - a object with name and parameters
    def self.load_function(file)
      f = new(file)
      @model = OpenStruct.new(:name => f.definition.name,
                              :parameters => f.parameter_list,
                              :parameter_names => f.parameter_list.keys)
      @model
    end

    def ast
      unless @ast
        raise ArgumentError, 'please set the manifest file' if manifest_file.nil?
        parser = ::Puppet::Pops::Parser::EvaluatingParser.new
        result = parser.parse_file(manifest_file)
        @ast = result.current
      end
      @ast
    end

    def dumper
      @dumper ||= Retrospec::Puppet::RspecDumper.new
    end

    def definition
      ast.body
    end

    # return a manifest body object
    def body
      ast.body.body
    end

    def parameters
      ast.body.parameters
    end

    def function_name
      body.name
    end

    def parameter_list
      list = {}
      parameters.each { |p| list[p.name.to_sym] = p.value }
      list
    end
  end
end
