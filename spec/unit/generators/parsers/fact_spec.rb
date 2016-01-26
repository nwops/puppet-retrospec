require 'spec_helper'

describe "facter" do
  let(:model) do
    Retrospec::Puppet::Generators::Facter.load_fact(file)
  end

  describe 'node_role' do
    let(:file) do
      File.join(fixtures_facts_path , 'node_role.rb')
    end
    it 'can eval code' do
      fact_name = model.facts.keys.first
      expect(fact_name).to eq(:node_role)
      fact_data = model.facts[fact_name]
      confines = fact_data.confines
      model_facts = model.facts[fact_name].used_facts
      global_used_facts = model.global_used_facts
      expect(confines).to eq({:kernel=>"Windows", :is_virtual=>true})
      expect(model_facts).to eq({})
      expect(global_used_facts).to eq({})
    end
  end


  describe 'multiple facts' do
    let(:file) do
      File.join(fixtures_facts_path , 'datacenter_facts.rb')
    end

    it 'can eval code with multiple facts' do
      global_used_facts = model[:global_used_facts]
      fact_name = model.facts.keys.first
      fact_data = model.facts[fact_name]
      confines = fact_data.confines
      model_facts = fact_data.used_facts
      expect(fact_name).to eq(:fact1)
      expect(confines).to eq({:kernel=>"Linux"})
      expect(model_facts).to eq({})
      expect(global_used_facts).to eq({})
      fact_name = model.facts.keys.last
      fact_data = model.facts[fact_name]
      confines = fact_data.confines
      model_facts = fact_data.used_facts
      expect(fact_name).to eq(:fact2)
      expect(confines).to eq({:kernel=>"Windows"})
      expect(model_facts).to eq({})
      expect(global_used_facts).to eq({})
    end
  end

  describe 'fact value' do
    let(:file) do
      File.join(fixtures_facts_path , 'facts_with_methods.rb')
    end
    it 'can be processed' do
      expect(model).to_not eq(nil)
    end

  end

end