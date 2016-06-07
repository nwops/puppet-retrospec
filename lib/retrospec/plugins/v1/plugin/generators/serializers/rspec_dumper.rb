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
          if ENV['RETROSPEC_LOGGER_LEVEL'] == 'debug'
            @logger.level = Logger::DEBUG
          else
            @logger.level = Logger::INFO
          end
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
        when :do
          result << format_r([x.to_s, :indent, :break])
        when :end
          result << format_r([:dedent, :break,x.to_s])
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

      def dump_ResourceTypeDefinition o
        result = ["describe #{o.name.inspect}", :do]
        result << ['let(:title) do',:indent, :break, 'XXreplace_meXX'.inspect, :break]
        result << [:end, :dedent, :break]
        result << [:indent, :break,'let(:params)', :do, '{', :break]
        result << o.parameters.collect {|k| do_dump(k)}
        result << ['}', 'end']
        # result << ["inherits", o.parent_class] if o.parent_class
        # we need to process the body so that we can relize which facts are used
        body_result = []
        if o.body
          body_result << [:break, do_dump(o.body)]
        else
          body_result << []
        end
        result << [:break,:break,'let(:facts)', :do, '{',:break]
        result << dump_top_scope_vars
        result << ['}',:end]
        result << body_result
        result << [:end]
        result
      end

      def top_scope_vars
        var_store.find_all do |k,v|
          v[:type] == :top_scope
        end
      end

      #
      def dump_top_scope_vars
        result = []
        top_scope_vars.sort.each do |k, v|
          result << ['  ',k.gsub('$::', '').inspect, '=>',v[:value].inspect + ',', :break ]
        end
        result
      end

      def dump_HostClassDefinition o
        result = ["describe #{o.name.inspect}", :do]
        result << ['let(:params)', :do, '{', :break]
        result << o.parameters.collect {|k| do_dump(k)}
        result << ['}', :end]
        # result << ["inherits", o.parent_class] if o.parent_class
        # we need to process the body so that we can relize which facts are used
        body_result = []
        if o.body
          body_result << [do_dump(o.body)]
        else
          body_result << []
        end
        result << [:break,:break,'let(:facts)', :do, '{',:break]
        result << dump_top_scope_vars
        result << ['}',:end]
        result << body_result
        result << [:end]
        result
      end

      # Produces parameters as name, or (= name value)
      def dump_Parameter o
        name_prefix = o.captures_rest ? '*' : ''
        name_part = "#{name_prefix}#{o.name}"
        data_type = do_dump(do_dump(o.value)).first || do_dump(o.type_expr)
        # records what is most likely a variable of some time and its value
        variable_value = do_dump(o.value)
        # need a case for Puppet::Pops::Model::LambdaExpression
        if o.eContainer.class == ::Puppet::Pops::Model::LambdaExpression
          add_var_to_store("#{name_part}", variable_value, false, :lambda_scope)
        else
          parent_name = o.eContainer.name
          add_var_to_store("#{parent_name}::#{name_part}", variable_value, false, :parameter)
        end
        if o.value && o.type_expr
          value = {:type => data_type, :name => name_part, :required => false, :default_value => variable_value}
        elsif o.value
          value = {:type => data_type, :name => name_part, :default_value => variable_value, :required => false}
        elsif o.type_expr
          value = {:type => data_type, :name => name_part, :required => true,  :default_value => ''}
        else
          value = {:type => data_type, :name => name_part, :default_value => '', :required => true}
        end
        if value[:required]
          ['  ', "#{value[:name].to_sym.inspect}", '=>', 'nil,', :break]
        else
          ['  ', "##{value[:name].to_sym.inspect}", '=>', value[:default_value].inspect + ',', :break]
        end
      end

      # this will determine and dump the resource requirement by
      # comparing itself against the resource relationship expression
      def dump_Resource_Relationship o
        result = []
        id = o.eContainer.object_id # the id of this container
        relationship = o.eContainer.eContainer.eContainer.eContents.first
        if relationship.respond_to?(:left_expr)
          if relationship.left_expr.object_id == id
            type_name = dump(relationship.right_expr.type_name).capitalize
            titles = relationship.right_expr.bodies.map{|b| dump(b.title)}
            result << ['"that_comes_before"', '=>', "'#{type_name}#{titles}',".gsub("\"", '') ]
          else
            if relationship.left_expr.respond_to?(:type_name)
              type_name = dump(relationship.left_expr.type_name).capitalize
              titles = relationship.left_expr.bodies.map{|b| dump(b.title)}
              result << ['"that_requires"', '=>', "'#{type_name}#{titles}',".gsub("\"", '')]
            end
          end
        end
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

      def method_missing(name, *args, &block)
        logger.debug("Method #{name} called".warning)
        []
      end

      # Interpolated strings are shown as (cat seg0 seg1 ... segN)
      def dump_ConcatenatedString o
        o.segments.collect {|x| do_dump(x)}.join
      end

      # Interpolation (to string) shown as (str expr)
      def dump_TextExpression o
        [do_dump(o.expr)]
      end

      # outputs the value of the variable
      # @param VariableExpression
      # @return String the value of the variable or the name if value is not found
      def dump_VariableExpression o
        key = dump(o.expr)
        if value = lookup_var(key)
          value  # return the looked up value
        elsif [::Puppet::Pops::Model::AttributeOperation,
           ::Puppet::Pops::Model::AssignmentExpression].include?(o.eContainer.class)
          "$#{key}"
        else
          add_var_to_store(key, "$#{key}", false, :class_scope)
        end
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
        result = [:break]
        o.statements.each {|x| result << do_dump(x) }
        result
      end

      # this is the beginning of the resource not the body itself
      def dump_ResourceExpression o
        result = []
        o.bodies.each do |b|
          result << :break << do_dump(b)
        end
        #result << :dedent
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
        [key.inspect, o.operator, value.inspect + ',']
      end

      # x[y] prints as (slice x y)
      def dump_AccessExpression o
        "#{do_dump(o.left_expr).capitalize}" + do_dump(o.keys).to_s.gsub("\"",'')
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
        o.value
      end

      def dump_LiteralList o
        o.values.collect {|x| do_dump(x)}
      end

      def dump_LiteralHash o
        data = o.entries.collect {|x| do_dump(x)}
        Hash[*data.flatten]
      end

      def dump_LiteralString o
        "#{o.value}"
      end

      def dump_LiteralDefault o
        ":default"
      end

      def dump_LiteralUndef o
        :undef
      end

      def dump_LiteralRegularExpression o
        "/#{o.value.source}/"
      end

      def dump_Nop o
        ":nop"
      end

      def dump_NilClass o
        :undef
      end

      def dump_NotExpression o
        ['!', dump(o.expr)]
      end

      def dump_CapabilityMapping o
        [o.kind, do_dump(o.component), o.capability, do_dump(o.mappings)]
      end

      def dump_ParenthesizedExpression o
        do_dump(o.expr)
      end

      # Hides that Program exists in the output (only its body is shown), the definitions are just
      # references to contained classes, resource types, and nodes
      def dump_Program(o)
        dump(o.body)
      end

      def dump_Object o
        []
      end

      def is_nop? o
        o.nil? || o.is_a?(::Puppet::Pops::Model::Nop)
      end

    end
  end
end
