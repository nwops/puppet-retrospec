require_relative 'resource'

class Conditional
  attr_reader :test, :value, :statements

  # things I need:  a key/value store for variables
  # types of variables
  # those that can be changed
  # those that can be influenced (facts, other variables that contain variables)
  # takes a subtype of Puppet::AST::Branch that contains conditional logic
  def initialize(branch, _parameters)
    @statements = branch.statements
  end

  # get the attributes for the given resources found in the type code passed in
  # this will return a array of hashes, one for each resource found
  def self.all(type)
    r_attrs = []
    generate_conditionals(type).each do |c|
      r_attrs << Resource.all(c.statements)
    end
    r_attrs.flatten
  end

  # a array of types the are known to contain conditional code and statements
  def self.types
    # test, statement, value
    # if I don't have a statement that I am part of a bigger code block
    # [Puppet::Parser::AST::IfStatement, Puppet::Parser::AST::CaseStatement, Puppet::Parser::AST::Else,
    #  Puppet::Parser::AST::CaseOpt, Puppet::Parser::AST::Selector]
    [Puppet::Parser::AST::IfStatement, Puppet::Parser::AST::Else]
  end

  # returns a array of branch subtypes
  def self.find_conditionals(type)
    conds = []
    if type.code.respond_to?(:find_all)
      conds = type.code.find_all { |c| types.include?(c.class) }
    end
    conds
  end

  # find and create an array of conditionals
  # we need the type so we can look through the code to find conditional statements
  def self.generate_conditionals(type)
    conditionals = []
    find_conditionals(type).each do |cond|
      conditionals << Conditional.new(cond, type.arguments)
    end
    conditionals
  end
end
