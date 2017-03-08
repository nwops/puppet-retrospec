require 'ostruct'
# this is required to use when processing erb templates
class OpenStruct
  def get_binding
    binding
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

        def initialize(name, options, &block)
          @fact_name = name
        end

        def self.exec_calls
          @exec_calls ||= {}
        end

        def self.used_facts
          @used_facts ||= {}
        end

        def self.methods_defined
          @methods_defined ||= []
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
          unless methods_defined.include?(method_sym)
            methods_defined << method_sym
          end
          method_sym
        end

        def self.setcode(&block)
          begin
            block.call
          rescue Exception => e
          rescue NameError => e
          end
        end

        def self.confine(fact, *values)
          @confines << fact
        end

        # loads the fact into the loader for evaluation
        # and data collection
        def self.load_fact(file)
          @model = OpenStruct.new(:facts => {}, :defined_methods => [], :global_used_facts => {}, :global_used_execs => {})
          begin
            proc = Proc.new {}
            eval(File.read(file), proc.binding, file)
          rescue LoadError => e
            puts "Error loading dependency for file: #{file}, skipping".fatal
          rescue Exception => e
            puts "Error evaluating file: #{file}, skipping".fatal
          end
          @model
        end

        # every fact will have a Facter.add functionality
        # this is the startign point to collect all data
        def self.add(name, options={}, &block)
          # calls the facter.add block
          # this may call separate confine statements
          # for each Facter.add block that gets called we need to reset a few things
          @confines = {}
          @used_facts = {}
          @exec_calls = {}
          begin
            block.call
          rescue Exception => e
          rescue NameError => e
          end

          @model.facts[name] = OpenStruct.new(:fact_name => name)
          @model.facts[name].used_facts = used_facts
          @model.facts[name].confines = @confines
          @model.defined_methods = methods_defined
          @model.facts[name].exec_calls = exec_calls
          @model
        end
      end
     end
  end
end