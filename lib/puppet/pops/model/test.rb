#!/usr/bin/env ruby
#
#
require 'pry'
require 'puppet'
require 'puppet/pops'
#require_relative 'test_dumper'
require_relative 'schema_dumper'

parser = Puppet::Pops::Parser::EvaluatingParser.new
result = parser.parse_file('/Users/cosman/singlestone/modules/sql2014/manifests/init.pp')
ast = result.current
class_def = ast.body
parameters = class_def.parameters

#parameters.last.eContents
#=> [Puppet::Pops::Model::LiteralHash, Puppet::Pops::Model::AccessExpression]
#[8] pry(main)> parameters.last.eContents.last
#=> Puppet::Pops::Model::AccessExpression
#[9] pry(main)> parameters.last.eContents.last.eContents
#=> [Puppet::Pops::Model::QualifiedReference, Puppet::Pops::Model::QualifiedReference]
dumper = SchemaDumper.new
puts dumper.dump(result)
binding.pry
