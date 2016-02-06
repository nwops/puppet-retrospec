require 'puppet'
require 'puppet/pops/model/tree_dumper'
# Dumps a Pops::Model in reverse polish notation; i.e. LISP style
# The intention is to use this for debugging output
# TODO: BAD NAME - A DUMP is a Ruby Serialization
#
module Retrospec
  module Puppet
    class RspecDumper < ::Puppet::Pops::Model::TreeDumper
      attr_reader :var_store

      def var_store
        @var_store ||= {}
      end

      def logger
        unless @logger
          require 'logger'
          @logger = Logger.new(STDOUT)
          @logger.level = Logger::DEBUG
        end
        @logger
      end

      def lookup_var(key)
        # if exists, return value
        # if it doesn't exist, store and return key
        key = normalize_key(key)
        other_key = key.split('::').last
        if key != other_key
          other_key = "$#{other_key}"
        end
        logger.debug("looking up #{key}".yellow)
        if item = var_store[key]
          value = item[:value]
          logger.debug("Store hit: #{key} with value: #{value}")
        elsif item = var_store[other_key] # key does not exist
          logger.debug("looking up #{other_key}".yellow)
          logger.debug("Store hit: #{other_key} with value: #{value}")
          value = item[:value]
        else
          logger.debug("Store miss: #{key}".fatal)
          value = false
        end
        value
      end

      # prepends a dollar sign if doesn't already exist
      def normalize_key(key)
        unless key.start_with?('$')
          # prepend the dollar sign
          key = "$#{key}"
        end
        key
      end

      # adds a variable to the store, its value and type of scope
      def add_var_to_store(key, value, force=false, type=:scope)
        key = normalize_key(key)
        if var_store.has_key?(key) and !force
          logger.debug ("Prevented from writing #{key} with value #{value}".info)
        else
          logger.debug("storing #{key} with value #{value}".yellow)
          var_store[key]= {:value => value, :type => type}
          other_key = key.split('::').last
          if key != other_key
            other_key = "$#{other_key}"
            unless key.split('::').first == '$'
              add_var_to_store(other_key, value, false, type)
            end

          end
        end
        value
      end

      def dump_Array o
        o.collect {|e| do_dump(e) }
      end

      def indent
        "  " * indent_count
      end

      def format(x)
        result = ""
        parts = format_r(x)
        parts.each_index do |i|
          if i > 0
            # separate with space unless previous ends with whitepsace or (
            result << ' ' if parts[i] != ")" && parts[i-1] !~ /.*(?:\s+|\()$/ && parts[i] !~ /^\s+/
          end
          result << parts[i].to_s
        end
        result
      end

      def format_r(x)
        result = []
        case x
        when :break
          result << "\n" + indent
        when :indent
          @indent_count += 1
        when :dedent
          @indent_count -= 1
        when Array
          #result << '('
          result += x.collect {|a| format_r(a) }.flatten
          #result << ')'
        when Symbol
          result << x.to_s # Allows Symbols in arrays e.g. ["text", =>, "text"]
        else
          result << x
        end
        result
      end

      def dump_CaseExpression o
        expr_name = dump(o.test.expr)
        expr_value = dump(o.test)
        result = ["describe '#{expr_name}' do"]
        result << [:indent, :break,'let(:params) do',:indent, :break]
        #TODO figure out if the expr_name is a param and than we can mock it here
        result << 'params.merge({})' # merge in the parent level params
        result << [:dedent, :break, 'end']
        result << [:break,'let(:facts) do',:break]
        result << [:break, 'end']
        o.options.each do |s|
          result << :break << do_dump(s)
        end
        result << :dedent
      end

      # outputs the value of the variable
      def dump_VariableExpression o
        key = dump(o.expr)
        if value = lookup_var(dump(o.expr))
          value  # return the looked up value
        else
          add_var_to_store(key, "$#{dump(o.expr)}", false, :top_scope)
        end
      end

      def dump_CaseOption o
        expr_name = dump(o.eContainer.test.expr)
        expr_value = dump(o.eContainer.test)
        result = []
        o.values.each do |x|
          test_name = do_dump(x)
          result << ["context #{test_name} do", :indent, :break]
          result << [do_dump(o.then_expr)]
        end
        result << [:dedent,:break, :end]
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
        result = ["context '#{test_name}' do", :indent, :break]
        then_name = do_dump(o.then_expr)
        result << then_name
        else_name = do_dump(o.else_expr) unless is_nop? o.else_expr
        result << else_name
        result << [:dedent, :break, :end]
        result
      end

      def top_scope_vars
        var_store.find_all do |k,v|
          v[:type] == :top_scope
        end
      end

      def dump_top_scope_vars
        result = []
        top_scope_vars.each do |k, v|
          result << [k.gsub('$::', ':'), '=>',"#{v[:value]},", :break ]
        end
        result
      end

      def dump_HostClassDefinition o
        result = ["describe #{o.name.to_sym.inspect} do"]
        result << [:indent, :break,'let(:params) do',:indent, :break]
        result << o.parameters.collect {|k| do_dump(k)}
        result << [:dedent, :break, 'end']
        # result << ["inherits", o.parent_class] if o.parent_class
        # we need to process the body so that we can relize which facts are used
        body_result = []
        if o.body
          body_result << [:break, do_dump(o.body)]
        else
          body_result << []
        end
        result << [:break,'let(:facts) do',:indent, :break]
        result << dump_top_scope_vars
        result << [:dedent, :break, 'end']
        result << body_result
        result << [:dedent,:break, 'end']
        result
      end

      # Produces parameters as name, or (= name value)
      def dump_Parameter o
        name_prefix = o.captures_rest ? '*' : ''
        name_part = "#{name_prefix}#{o.name}"
        data_type = do_dump(do_dump(o.value)).first || do_dump(o.type_expr)
        # records what is most likely a variable of some time and its value
        variable_value = do_dump(o.value)
        parent_name = o.eContainer.name
        add_var_to_store("#{parent_name}::#{name_part}", variable_value, false, :parameter)

        if o.value && o.type_expr
          value = {:type => data_type, :name => name_part, :required => false, :default_value => "#{variable_value},"}
        elsif o.value
          value = {:type => data_type, :name => name_part, :default_value => "#{variable_value},", :required => false}
        elsif o.type_expr
          value = {:type => data_type, :name => name_part, :required => true,  :default_value => ','}
        else
          value = {:type => data_type, :name => name_part, :default_value => ',', :required => true}
        end
        if value[:required]
          ["#{value[:name].to_sym.inspect}", '=>', value[:default_value], :break]
        else
          ["##{value[:name].to_sym.inspect}", '=>', value[:default_value], :break]
        end
      end

      def dump_ResourceBody o
        type_name = do_dump(o.eContainer.type_name).gsub('::', '__')
        title = do_dump(o.title)
        result = ['it do', :indent, :break, "is_expected.to contain_#{type_name}(#{title})"]
        # this determies if we should use the with() or not
        if o.operations.count > 0
          result << [ :indent, :break,'.with({', :indent, :break]
          o.operations.each do |p|
            result << [do_dump(p), :break]
          end
          result << [ :dedent, :break, '})', :indent, :dedent, :dedent]
        end
        result << [:dedent, :break, 'end', :break]
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

      # this doesn't return anything as we use it to store variables
      def dump_AssignmentExpression o
        oper = o.operator.to_s
        result = []
        case oper
        when '='
          # we don't know the output type of a function call, so just assign nill
          # no need to add it to the var_store since its always the same
          # without this separation, values will get stored
          if o.right_expr.class == ::Puppet::Pops::Model::CallNamedFunctionExpression
            value = nil
          else
            value = dump(o.right_expr)
            key = dump(o.left_expr)
            # we dont want empty variables storing empty values
            unless key == value
              add_var_to_store(key, value, true)
            end
          end
          result
        else
          [o.operator.to_s, do_dump(o.left_expr), do_dump(o.right_expr)]
        end
      end

      def dump_BlockExpression o
        #result = ["block", :indent]
        result = []
        o.statements.each {|x| result << :break; result << do_dump(x) }
        result << :break
        result
      end

      def dump_RelationshipExpression o
        [o.operator.to_s, do_dump(o.left_expr), do_dump(o.right_expr)]
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

      def dump_LiteralInteger o
        case o.radix
        when 10
          o.value.to_s
        when 8
          "0%o" % o.value
        when 16
          "0x%X" % o.value
        else
          "bad radix:" + o.value.to_s
        end
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

      def dump_NamedDefinition o
        # the nil must be replaced with a string
        result = [nil, o.name]
        result << ["parameters"] + o.parameters.collect {|p| do_dump(p) } if o.parameters.size() > 0
        if o.body
          result << do_dump(o.body)
        else
          result << []
        end
        result
      end

      def dump_ResourceTypeDefinition o
        result = dump_NamedDefinition(o)
        result[0] = 'define'
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

      # this is the beginning of the resource not the body itself
      def dump_ResourceExpression o
        #form = o.form == :regular ? '' : o.form.to_s + "-"
        result = []
        o.bodies.each do |b|
          result << :break << do_dump(b)
        end
        #result << :dedent
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
