require 'retrospec/variable_store'

class Resource

  attr_reader :type, :title, :parameters, :scope_name

  def initialize(type_name,instance)
    # we don't store the resource parameters in the variablestore because they are never referenced
    @parameters = Hash[instance.parameters.map { |k| [k.param, VariableStore.resolve(k.value).gsub("\"", '')]}]
    @type = type_name
    @title = VariableStore.resolve(instance.title).gsub("\"", '')
  end

  # Gets all resources in the type that are not in a code block
  def self.all(statements)
    if statements.respond_to?(:code)
      # if we accidentally pass a type in without specifying the code
      statements = statements.code unless statements.nil?
    end
    a = []
    # sometimes the code is empty
    if statements.respond_to?(:find_all)
      res = statements.find_all { |s| s.instance_of?(Puppet::Parser::AST::Resource)}
      res.each do |r|
        r.instances.each do |i|
          a << Resource.new(r.type, i)
        end
      end
    end
    a
  end

  def self.all_resources
    ObjectSpace.each_object(Puppet::Parser::AST::Resource).map {|x| x}
  end
end