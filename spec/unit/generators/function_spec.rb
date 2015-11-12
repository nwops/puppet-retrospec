require 'spec_helper'

describe 'function' do

  describe 'v3 function' do
    let(:function_file) do
      File.join(sample_module_path, 'lib', 'puppet', 'parser', 'functions', 'sha1.rb')
    end

    let(:models) do
      Retrospec::Puppet::Parser::Functions.load_function(function_file)
    end

    it 'can eval' do
      expect(models.name).to eq(:sha1)
      expect(models.doc).to eq('Returns a SHA1 hash value from a provided string.')
      expect(models.type).to eq(:rvalue)
      expect(models.arity).to eq(1)
    end

    describe 'bad function' do
      let(:function_file) do
        File.join(sample_module_path, 'lib', 'puppet', 'parser', 'functions', 'bad_sha1.rb')
      end
      it 'should raise error' do
        expect{models.name}.to raise_error SyntaxError
      end
    end
  end

  describe 'v4 function' do
    let(:function_file) do
      File.join(sample_module_path, 'lib', 'puppet', 'functions', 'reduce.rb')
    end

    let(:models) do
      Retrospec::Puppet::Functions.load_function(function_file)
    end

    it 'can eval' do
      expect(models.name).to eq(:reduce)
    end

    it 'returns array of dispatched methods hashes' do
      expect(models.dispatched_methods).to be_instance_of(Hash)
    end

    it 'returns correct number of dispached methods' do
      expect(models.dispatched_methods.keys).to eq([:reduce_without_memo, :reduce_with_memo])
    end

    it 'returns params of dispatched method' do
      expect(models.dispatched_methods[:reduce_without_memo][:args].count).to eq(2)
      expect(models.dispatched_methods[:reduce_without_memo][:args].first[:name]).to eq(:param)
      expect(models.dispatched_methods[:reduce_without_memo][:args].last[:name]).to eq(:block_param)
    end

    it 'returns required methods' do
      expect(Retrospec::Puppet::Functions.find_required_methods(:reduce, [:reduce_without_memo, :reduce_with_memo])).to eq([:reduce_without_memo, :reduce_with_memo])
    end

    it 'returns required methods' do
      expect(Retrospec::Puppet::Functions.find_required_methods(:reduce)).to eq([:reduce])
    end

  end
end
