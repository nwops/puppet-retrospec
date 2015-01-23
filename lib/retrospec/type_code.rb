class TypeCode
  attr_reader :type, :variables, :scope_name

  #TODO figure out how to store vardef statements that are contained inside conditional blocks
  def initialize(type)
    @scope_name = type.name
    @type = type
  end

  def variables
    if @type.code.respond_to?(:find_all)
      @variables ||= @type.code.find_all {|i| i.instance_of?(Puppet::Parser::AST::VarDef) }
    else
      @variables = []
    end
    @variables
  end
end