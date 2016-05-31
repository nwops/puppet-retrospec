require 'puppet'
require 'puppet/pops/model/tree_dumper'
# Dumps a Pops::Model in reverse polish notation; i.e. LISP style
# The intention is to use this for debugging output
# TODO: BAD NAME - A DUMP is a Ruby Serialization
#
module Retrospec
  module Puppet
    class SchemaDumper < ::Puppet::Pops::Model::TreeDumper
      # conversion table from ruby types to kwalify types
      def type_table
        @type_table ||= {
          'Array'=>"seq",
          'Hash'=>"map",
          'string' => 'str',
          'String'=>"str",
          'Integer'=>"int",
          'Float'=>"float",
          'Numeric'=>"number",
          'Date'=>"date",
          'Time'=>"timestamp",
          'Object'=>"any",
          'FalseClass' => 'bool',
          'TrueClass' => 'bool',
          'Fixnum' => 'number',
          'NilClass' => 'any',
          'Puppet::Pops::Model::LiteralBoolean' => 'bool',
          'Puppet::Parser::AST::Variable' => 'any',
          'Puppet::Parser::AST::Boolean' => 'bool',
          'Puppet::Parser::AST::String' => 'str',
          'Puppet::Parser::AST::ASTHash' => 'map',
          'Puppet::Parser::AST::ASTArray' => 'seq',
        }
      end

      def dump_Object o
        [o.class.to_s, o.to_s]
      end

      def dump(o)
        do_dump(o)
      end

      def do_dump(o)
        @@dump_visitor.visit_this_0(self, o)
      end

      def dump_Array o
        'seq'
        #o.collect {|e| do_dump(e) }
      end

      def indent
        "  " * indent_count
      end

      # convert the given class to a kwalify class, defaults to any
      def to_kwalify_type(value)
        if x = dump(value)
          x
        else
          'any'
        end
      end

      def dump_QualifiedName o
        'any'  # return any until we can lookup the value of this variable name
      end

      def dump_LiteralFloat o
        'float'
      end

      def dump_LiteralInteger o
        'int'
      end

      def dump_LiteralBoolean o
        'bool'
      end

      def dump_LiteralValue o
        type_table[o.class.to_s] || 'any'
      end

      def dump_Expression o
        do_dump(o.value)
      end

      def dump_Application o
        ["application", o.name, do_dump(o.parameters), do_dump(o.body)]
      end

      def dump_ArithmeticExpression o
        [o.operator.to_s, do_dump(o.left_expr), do_dump(o.right_expr)]
      end

      # x[y] prints as (slice x y)
      def dump_AccessExpression o
        if o.keys.size <= 1
          ["slice", do_dump(o.left_expr), do_dump(o.keys[0])]
        else
          ["slice", do_dump(o.left_expr), do_dump(o.keys)]
        end
      end

      def dump_MatchesExpression o
        [o.operator.to_s, do_dump(o.left_expr), do_dump(o.right_expr)]
      end

      def dump_CollectExpression o
        result = ["collect", do_dump(o.type_expr), :indent, :break, do_dump(o.query), :indent]
        o.operations do |ao|
          result << :break << do_dump(ao)
        end
        result += [:dedent, :dedent ]
        result
      end

      def dump_EppExpression o
        result = ["epp"]
        #    result << ["parameters"] + o.parameters.collect {|p| do_dump(p) } if o.parameters.size() > 0
        if o.body
          result << do_dump(o.body)
        else
          result << []
        end
        result
      end

      def dump_ExportedQuery o
        result = ["<<| |>>"]
        result += dump_QueryExpression(o) unless is_nop?(o.expr)
        result
      end

      def dump_VirtualQuery o
        result = ["<| |>"]
        result += dump_QueryExpression(o) unless is_nop?(o.expr)
        result
      end

      def dump_QueryExpression o
        [do_dump(o.expr)]
      end

      def dump_ComparisonExpression o
        [o.operator.to_s, do_dump(o.left_expr), do_dump(o.right_expr)]
      end

      def dump_AndExpression o
        ["&&", do_dump(o.left_expr), do_dump(o.right_expr)]
      end

      def dump_OrExpression o
        ["||", do_dump(o.left_expr), do_dump(o.right_expr)]
      end

      def dump_InExpression o
        ["in", do_dump(o.left_expr), do_dump(o.right_expr)]
      end

      def dump_AssignmentExpression o
        [o.operator.to_s, do_dump(o.left_expr), do_dump(o.right_expr)]
      end

      # Produces (name => expr) or (name +> expr)
      def dump_AttributeOperation o
        [o.attribute_name, o.operator, do_dump(o.value_expr)]
      end

      def dump_AttributesOperation o
        ['* =>', do_dump(o.expr)]
      end

      def dump_LiteralList o
        'seq'
        #["[]"] + o.values.collect {|x| do_dump(x)}
      end

      def dump_LiteralHash o
        'map'
        #["{}"] + o.entries.collect {|x| do_dump(x)}
      end

      def dump_KeyedEntry o
        [do_dump(o.key), do_dump(o.value)]
      end

      def dump_MatchExpression o
        [o.operator.to_s, do_dump(o.left_expr), do_dump(o.right_expr)]
      end

      def dump_LiteralString o
        'str'
        #"'#{o.value}'"
      end

      def dump_LambdaExpression o
        result = ["lambda"]
        result << ["parameters"] + o.parameters.collect {|p| do_dump(p) } if o.parameters.size() > 0
        if o.body
          result << do_dump(o.body)
        else
          result << []
        end
        result
      end

      def dump_LiteralDefault o
        ":default"
      end

      def dump_LiteralUndef o
        ":undef"
      end

      def dump_LiteralRegularExpression o
        "/#{o.value.source}/"
      end

      def dump_Nop o
        ":nop"
      end

      def dump_NamedAccessExpression o
        [".", do_dump(o.left_expr), do_dump(o.right_expr)]
      end

      def dump_NilClass o
        'any'
      end

      def dump_NotExpression o
        ['!', dump(o.expr)]
      end

      def dump_VariableExpression o
        do_dump(o.expr)
      end

      # Interpolation (to string) shown as (str expr)
      def dump_TextExpression o
        ["str", do_dump(o.expr)]
      end

      def dump_UnaryMinusExpression o
        ['-', do_dump(o.expr)]
      end

      def dump_UnfoldExpression o
        ['unfold', do_dump(o.expr)]
      end

      def dump_BlockExpression o
        result = ["block", :indent]
        o.statements.each {|x| result << :break; result << do_dump(x) }
        result << :dedent << :break
        result
      end

      # Interpolated strings are shown as (cat seg0 seg1 ... segN)
      def dump_ConcatenatedString o
        ["cat"] + o.segments.collect {|x| do_dump(x)}
      end

      def dump_ReservedWord o
        [ 'reserved', o.word ]
      end

      # Produces parameters as name, or (= name value)
      def dump_Parameter o
        name_prefix = o.captures_rest ? '*' : ''
        name_part = "#{name_prefix}#{o.name}"
        if o.value && o.type_expr
          {:type => do_dump(o.type_expr), :name => name_part, :default_value => do_dump(o.value)}
        elsif o.value
          {:type => nil, :name => name_part, :default_value => do_dump(o.value)}
        elsif o.type_expr
          {:type => do_dump(o.type_expr), :name => name_part, :default_value => nil}
        else
          {:type => nil, :name => name_part, :default_value => nil}
        end
      end

      def is_nop? o
        o.nil? || o.is_a?(Puppet::Pops::Model::Nop)
      end
    end
  end
end
