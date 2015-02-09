require 'singleton'
require 'retrospec/type_code'

class VariableStore
  attr_reader :store

  include Singleton

  def initialize
    @store = {}
  end

  def self.instance
    @@instance ||= new
  end

  # key should be a variable starting with $
  # enable_value_conversion converts the value to a string
  def self.add(key, value, enable_value_conversion=true)
    key = "$#{key.to_s}" unless key.to_s.start_with?('$')
    if value.instance_of?(String) or value.instance_of?(Puppet::Parser::AST::String)
      value = value.to_s.gsub("\"",'')
    end
    if enable_value_conversion
      instance.store[key.to_s] = value.to_s
    else
      instance.store[key.to_s] = value
    end
  end

  # lookup the key in the hash, if we dont' find it lets just return the string representation
  def self.lookup(key)
    key = "$#{key.to_s}" unless key.to_s.start_with?('$')
    begin
      value = VariableStore.instance.store.fetch(key.to_s)
      # try and resolve if necessary
      if [Puppet::Parser::AST::Variable,Puppet::Parser::AST::VarDef].include?(value.class)
        value = resolve(value)
      else
        if captures = value.scan(/(\$\w+)/).flatten
          # produces an array of variables that have not been resolved yet
          #  ["$concat1", "$concat"] = "$concat1/test3183/$concat"
          captures.each { |c| value.gsub(c, resolve(c))}
        end
      end
    rescue
      return key
    end
    value
  end

  def self.variable_resolution(variable)
    res = nil
    if variable.instance_of? Puppet::Parser::AST::VarDef
      res = lookup(variable.name.value)
      add(variable.name, variable.value,false) unless res.nil?
    elsif variable.instance_of?(Puppet::Parser::AST::Variable)
      res = lookup(variable.value)
    elsif variable.instance_of?(Puppet::Parser::AST::Concat)
      begin
        res = variable.value.map { |i| variable_resolution(i)}.join.gsub("\"",'')
      rescue
        res = variable.value
      end
    else
      # I give up, I can't find the variable value so will just assign the variable name
      res = variable.to_s
    end
    if not res.nil?
      if variable.instance_of?(Puppet::Parser::AST::Variable)
        if not VariableStore.instance.store.keys.include?(variable.to_s)
          add(variable, res)
        end
      end
    end
    res
  end

  # will try and resolve the variable to a value by consulting the variables hash
  def self.resolve(variable)
    res = variable_resolution(variable)
  end

  # gets all the variables and parameters and passes them through the resolve function to populate the variable store
  def self.populate(type)
    type.arguments.each {|k,v| add(k,v,true)}
    TypeCode.new(type).variables.each {|v| add(v.name, resolve(v.value))}
  end
end
