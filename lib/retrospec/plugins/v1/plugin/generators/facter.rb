require 'ostruct'
# this is required to use when processing erb templates
class OpenStruct
  def get_binding
    binding()
  end
end

module Retrospec
  module Puppet
    module Generators
      class Facter
        # anytime a fact uses a facter lib we need to "mock" the fuction and record the value
        class Core
          class Execution
            def self.execute(command, options={})
              value = {:klass => self.to_s.gsub('Retrospec::Puppet::Generators::', ''),
              :method => :execute, :value => command}
              Retrospec::Puppet::Generators::Facter.exec_calls[command] = value
            end
          end
        end

        @model = OpenStruct.new(:facts => {})
        @used_facts = {}
        @confines = []
        @methods_defined = []

        def initialize(name, options, &block)
          @fact_name = name
          #block.call
        end

        def self.exec_calls
          @exec_calls ||= {}
        end

        def self.used_facts
          @used_facts ||= {}
        end

        def self.value(name)
          used_facts[name] = {:name => name}
        end

        def self.fact(name)
          fake_fact = OpenStruct.new(:value => '')
          used_facts[name] = {:name => name}
          fake_fact
        end

        def self.method_missing(method_sym, *arguments, &block)
          @methods_defined << method_sym
        end

        def self.setcode(&block)
          begin
            block.call
          rescue NameError => e
          end
        end

        def self.confine(fact, *values)
          @confines << fact
        end

        # loads the fact into the loader for evaluation
        # and data collection
        def self.load_fact(file)
          @model = OpenStruct.new(:facts => {})
          @used_facts = {}
          @model = eval(File.read(file))
          transform_data(@model)
        end

        # every fact will have a Facter.add functionality
        # this is the startign point to collect all data
        def self.add(name, options={}, &block)
          @model.facts[name] = OpenStruct.new(:fact_name => name)
          # calls the facter.add block
          # this may call separate confine statements
          @model.global_used_facts = used_facts
          @used_facts = {}  # clear before fact specific are evaluated
          @model.global_used_execs = exec_calls
          @exec_calls = {}
          begin
            block.call
          rescue NameError => e
          end
          @model.facts[name].used_facts = used_facts
          @model.facts[name].confines = @confines
          # clear any persistant data
          @confines = []
          @model.defined_methods = @methods_defined
          @model.facts[name].exec_calls = exec_calls
          @model
        end

        def self.transform_data(data)
          #ObenStruct.new(:)
          # {:method_fact=>
          #      {:fact_name=>:method_fact,
          #       :used_facts=>{:is_virtual=>{:name=>:is_virtual}},
          #       :confines=>[{:kernel=>"Linux"}],
          #       :exec_calls=>["which lsb"]},
          #  :global_used_facts=>{},
          #  :global_used_execs=>[],
          #  :defined_methods=>[:default_kernel]}
          data
        end
      end

     end
  end
end
