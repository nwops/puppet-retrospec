require 'puppet'
require_relative 'rspec_dumper'

# Dumps a Pops::Model in reverse polish notation; i.e. LISP style
# The intention is to use this for debugging output
# TODO: BAD NAME - A DUMP is a Ruby Serialization
#
module Retrospec
  module Puppet
    class RspecDumperFull < Retrospec::Puppet::RspecDumper

      def dump_CaseExpression o
        expr_name = dump(o.test.expr)
        expr_value = dump(o.test)
        result = ["describe '#{expr_name}'",:do]
        result << ['let(:params)',:do]
        #TODO figure out if the expr_name is a param and than we can mock it here
        result << 'params.merge({})' # merge in the parent level params
        result << [:end]
        result << [:break,'let(:facts)', :do]
        result << [:end]
        o.options.each do |s|
          result << :break << do_dump(s)
        end
        result << :dedent
      end

      def dump_CaseOption o
        expr_name = dump(o.eContainer.test.expr)
        expr_value = dump(o.eContainer.test)
        result = []
        o.values.each do |x|
          test_name = do_dump(x)
          result << ["context #{test_name}", :do]
          result << [do_dump(o.then_expr)]
        end
        result << [:end]
        result
      end

      def dump_ResourceBody o
        type_name = do_dump(o.eContainer.type_name).gsub('::', '__')
        title = do_dump(o.title).inspect
        #TODO remove the :: from the front of the title if exists
        result = ['it', :do, "is_expected.to contain_#{type_name}(#{title})"]
        # this determies if we should use the with() or not
        if o.operations.count > 0
          result << [ :indent, :break,'.with({', :indent, :break]
          o.operations.each do |p|
            result << [do_dump(p), :break]
          end
          unless [::Puppet::Pops::Model::CallNamedFunctionExpression, ::Puppet::Pops::Model::BlockExpression].include?(o.eContainer.eContainer.class)
            result << dump_Resource_Relationship(o)
          end
          result << [ :dedent, :break, '})', :indent, :dedent, :dedent]
        end
        result << [:end, :break]
        result
      end

      def dump_IfExpression o
        # this should be a test becuase if its function
        #Puppet::Pops::Model::CallNamedFunctionExpression
        case o.test
        when ::Puppet::Pops::Model::ComparisonExpression
          test_name = dump(o.test)
        when ::Puppet::Pops::Model::CallNamedFunctionExpression
          test_name = "#{dump(o.test.functor_expr)}(#{o.test.arguments.collect { |a| dump(a.expr)}})"
        end
        result << ["context #{test_name}", :do]
        then_name = do_dump(o.then_expr)
        result << then_name
        else_name = do_dump(o.else_expr) unless is_nop? o.else_expr
        result << else_name
        result << [:end]
        result
      end

      # Interpolated strings are shown as (cat seg0 seg1 ... segN)
      def dump_ConcatenatedString o
        o.segments.collect {|x| do_dump(x)}
      end

      # Interpolation (to string) shown as (str expr)
      def dump_TextExpression o
        [do_dump(o.expr)]
      end

      def dump_CallNamedFunctionExpression o
        func_name = dump o.functor_expr
        args = o.arguments.collect {|a| do_dump(a) }.join(',')
        # because rspec-puppet cannot check if functions are called within a manifest
        # I don't think we can build a good test case here like
        # we could also mock the function here as well
        ["it { is_expected.to call(#{func_name}).with(#{args})}"]
      end

      def dump_CallMethodExpression o
        result = [o.rval_required ? "call-method" : "invoke-method", do_dump(o.functor_expr)]
        o.arguments.collect {|a| result << do_dump(a) }
        result << do_dump(o.lambda) if o.lambda
        result
      end

      # defines the resource expression and outputs -> when used
      # this would be the place to insert relationsip matchers
      def dump_RelationshipExpression o
        [do_dump(o.left_expr), do_dump(o.right_expr)]
      end

      # Produces (name => expr) or (name +> expr)
      def dump_AttributeOperation o
        key = o.attribute_name
        value = do_dump(o.value_expr) || nil
        [key.inspect, o.operator, "#{value},"]
      end

      def dump_LiteralFloat o
        o.value.to_s
      end

      def dump_LiteralValue o
        o.value.to_s
      end

      def dump_Factory o
        do_dump(o.current)
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
        "#{dump(o.left_expr)} #{o.operator} #{dump o.right_expr}"
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

      def dump_AttributesOperation o
        ['* =>', do_dump(o.expr)]
      end

      def dump_LiteralList o
        o.values.collect {|x| do_dump(x)}
      end

      def dump_LiteralHash o
        data = o.entries.collect {|x| do_dump(x)}
        Hash[*data.flatten]
      end

      def dump_KeyedEntry o
        [do_dump(o.key), do_dump(o.value)]
      end

      def dump_MatchExpression o
        [o.operator.to_s, do_dump(o.left_expr), do_dump(o.right_expr)]
      end

      def dump_LiteralString o
        "'#{o.value}'"
      end

      def dump_LambdaExpression o
        result = ["lambda"]
        result << ["parameters"] + o.parameters.collect {|p| do_dump(p) } if o.parameters.size > 0
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
        ":undef"
      end

      def dump_NotExpression o
        ['!', dump(o.expr)]
      end

      def dump_UnaryMinusExpression o
        ['-', do_dump(o.expr)]
      end

      def dump_UnfoldExpression o
        ['unfold', do_dump(o.expr)]
      end

      def dump_HeredocExpression(o)
        result = ["@(#{o.syntax})", :indent, :break, do_dump(o.text_expr), :dedent, :break]
      end

      def dump_NodeDefinition o
        result = ["node"]
        result << ["matches"] + o.host_matches.collect {|m| do_dump(m) }
        result << ["parent", do_dump(o.parent)] if o.parent
        if o.body
          result << do_dump(o.body)
        else
          result << []
        end
        result
      end

      def dump_SiteDefinition o
        result = ["site"]
        if o.body
          result << do_dump(o.body)
        else
          result << []
        end
        result
      end

      def dump_CapabilityMapping o
        [o.kind, do_dump(o.component), o.capability, do_dump(o.mappings)]
      end

      def dump_ResourceOverrideExpression o
        form = o.form == :regular ? '' : o.form.to_s + "-"
        result = [form+"override", do_dump(o.resources), :indent]
        o.operations.each do |p|
          result << :break << do_dump(p)
        end
        result << :dedent
        result
      end

      def dump_ReservedWord o
        [ 'reserved', o.word ]
      end

      def dump_ParenthesizedExpression o
        do_dump(o.expr)
      end

      # Hides that Program exists in the output (only its body is shown), the definitions are just
      # references to contained classes, resource types, and nodes
      def dump_Program(o)
        dump(o.body)
      end

      def dump_SelectorExpression o
        ["?", do_dump(o.left_expr)] + o.selectors.collect {|x| do_dump(x) }
      end

      def dump_SelectorEntry o
        [do_dump(o.matching_expr), "=>", do_dump(o.value_expr)]
      end

      def dump_SubLocatedExpression o
        ["sublocated", do_dump(o.expr)]
      end

      def dump_Object o
        [o.class.to_s, o.to_s]
      end

      def is_nop? o
        o.nil? || o.is_a?(::Puppet::Pops::Model::Nop)
      end

      def dump_RenderStringExpression o
        ["render-s", " '#{o.value}'"]
      end

      def dump_RenderExpression o
        ["render", do_dump(o.expr)]
      end

      def dump_ResourceDefaultsExpression o
        form = o.form == :regular ? '' : o.form.to_s + "-"
        result = [form+"resource-defaults", do_dump(o.type_ref), :indent]
        o.operations.each do |p|
          result << :break << do_dump(p)
        end
        result << :dedent
        result
      end

      def dump_UnlessExpression o
        result = ["unless", do_dump(o.test), :indent, :break,
          ["then", :indent, do_dump(o.then_expr), :dedent]]
          result +=
          [:break,
            ["else", :indent, do_dump(o.else_expr), :dedent],
            :dedent] unless is_nop? o.else_expr
        result
      end

    end
  end
end
