require 'singleton'
require 'retrospec/type_code'
require 'logger'

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
    key = key.to_s.gsub('$::', '$') if key.to_s.start_with?('$::')    # sometimes variables start with $::
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
    key = key.gsub('$::', '$') if key.to_s.start_with?('$::')    # sometimes variables start with $::
    begin
      value = VariableStore.instance.store.fetch(key.to_s)
      # try and resolve if necessary
      if [Puppet::Parser::AST::Variable,Puppet::Parser::AST::VarDef].include?(value.class)
        value = resolve(value)
      else
        if captures = value.scan(/(\$[::]?[\w+::]*\w+)/).flatten
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
  # the problem is that when it tries to lookup file name pieces it doesn't have the namespace
  # ie. $file_name/test3183/$some_var
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
  # we use recursion to evaluate inherited manifests
  # TODO use the same recursion method to evaluate included manifests
  def self.populate(type, is_parent=false)
    if type.parent
      p = type.parent.gsub(/\A::/, '')
      parent = type.resource_type_collection.hostclasses[p]
    else
      parent = nil
    end
    if parent
      # type has a parent and we want to add the parent variables first so we call populate first
      # then we load the type's variable
      populate(parent,true)
      # we load the local scope and top scope variables because we need access to both
      # there is a chance some of the local scope variables will be overwritten but by the time that happens
      # we won't need them anymore.
      type.arguments.each do |k,v|
        add(k.to_s,resolve(v),true)
        add(("$#{type.namespace}::" << k.to_s),resolve(v),true)
      end
      TypeCode.new(type).variables.each do |v|
        add(v.name.to_s, resolve(v.value))
        add(("$#{type.namespace}::" << v.name.to_s), resolve(v.value))
      end
    elsif is_parent
      # if this is the parent we load the variables
      type.arguments.each {|k,v| add(("$#{type.namespace}::" << k.to_s),resolve(v),true)}
      TypeCode.new(type).variables.each {|v| add(("$#{type.namespace}::" << v.name.to_s), resolve(v.value))}
    else
      # if the type does not have a parent we load the variables
      type.arguments.each do |k,v|
        add(k.to_s,resolve(v),true)
        add(("$#{type.namespace}::" << k.to_s),resolve(v),true)
      end
      TypeCode.new(type).variables.each do |v|
        add(v.name.to_s, resolve(v.value))
        add(("$#{type.namespace}::" << v.name.to_s), resolve(v.value))
      end
    end
  end
end
