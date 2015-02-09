require 'retrospec/puppet_module'
require 'retrospec/variable_store'

class TypeCode
  attr_reader :type, :variables, :scope_name, :parent

  #TODO figure out how to store vardef statements that are contained inside conditional blocks
  def initialize(type)
    raise 'UndefinedTypeError' unless type
    @scope_name = type.name
    @type = type
    @parent = type.parent
  end
  # need to figure out a way to load the parent or dependent manfifests
  def has_parent?
    @parent.nil?
  end

  # returns a list of variables found in the main code block
  def variables
    if @type.code.respond_to?(:find_all)
      @variables ||= @type.code.find_all {|i| i.instance_of?(Puppet::Parser::AST::VarDef) }
    else
      @variables = []
    end
    @variables
  end
end