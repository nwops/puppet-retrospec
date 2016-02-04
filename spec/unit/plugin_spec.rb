require 'spec_helper'
require 'retrospec'

describe 'puppet' do

  it 'can show the version' do
    expect(Retrospec::Puppet::VERSION).to be_instance_of(String)
  end
  let(:global_opts) do
    {}
  end

  let(:plugin_config) do
    {}
  end

  let(:args) do
    []
  end

  let(:global_config) do
    {}
  end

  let(:retrospec) do
    Retrospec::Plugins::V1::Puppet.run_cli(global_opts, global_config, plugin_config, args)
  end

  describe 'new_module' do

    let(:module_path) do
      '/tmp/testabc123'
    end

    before(:all) do
      ENV['RETROSPEC_PUPPET_AUTO_GENERATE'] = 'true'
    end

    let(:plugin_config) do
      {
        'plugins::puppet::template_dir' => retrospec_templates_path,
        'plugins::puppet::author' => 'test_name',
        'plugins::puppet::default_license' => 'Apache-3.0'
      }
    end


    describe 'without module path' do
      before(:each) do
        FileUtils.rm_rf('/tmp/testabc123')
      end

      let(:module_path) do
        '/tmp'
      end

      let(:global_opts) do
        {:module_path => module_path }
      end

      let(:args) do
        ['new_module', '-n', 'testabc123']
      end

      it 'should create a module when it does not exist' do
        retrospec
        expect(File.exist?(File.join(module_path, 'testabc123', 'manifests', 'init.pp'))).to eq(true)
        expect(File.exist?(File.join(module_path, 'testabc123', 'metadata.json'))).to eq(true)
        expect(File.exist?(File.join(module_path, 'testabc123', 'testabc123_schema.yaml'))).to eq(true)
        metadata = JSON.parse(File.read(File.join(module_path, 'testabc123', 'metadata.json')))
        expect(metadata['author']).to eq('test_name')
        expect(metadata['license']).to eq('Apache-3.0')
      end
    end

    describe 'with path' do
      let(:module_path) do
        '/tmp/testabc124'
      end

      let(:global_opts) do
        {:module_path => module_path }
      end

      before(:all) do
        FileUtils.rm_rf('/tmp/testabc124')
      end

      let(:args) do
        ['new_module', '-n', 'testabc124']
      end

      it 'should create a module when it does not exist' do
        retrospec
        expect(File.exist?(File.join(module_path, 'manifests', 'init.pp'))).to eq(true)
        expect(File.exist?(File.join(module_path, 'metadata.json'))).to eq(true)
        expect(File.exist?(File.join(module_path, 'testabc124_schema.yaml'))).to eq(true)
        metadata = JSON.parse(File.read(File.join(module_path, 'metadata.json')))
        expect(metadata['author']).to eq('test_name')
        expect(metadata['license']).to eq('Apache-3.0')
      end
    end
  end

  describe 'generator functions' do
    let(:module_path) do
      '/tmp/testabc123'
    end

    before(:all) do
      ENV['RETROSPEC_PUPPET_AUTO_GENERATE'] = 'true'
    end

    let(:plugin_config) do
      {
        'plugins::puppet::template_dir' => retrospec_templates_path,
        'plugins::puppet::author' => 'test_name'
      }
    end

    let(:global_opts) do
      {:module_path => module_path }
    end

    before(:each) do
      FileUtils.rm_rf(module_path)
      # ensure the module exists
      Retrospec::Plugins::V1::Puppet.run_cli(global_opts,
       global_config, plugin_config,
        ['new_module', '-n', 'testabc123'])
    end

    describe 'new_report' do
      let(:args) do
        ['new_report', '-n', 'test_report']
      end

      it 'should create report rb file' do
        report_file = File.join(module_path,'lib', 'puppet', 'reports', 'test_report.rb')
        retrospec
        expect(File.read(report_file)).to match(/Puppet::Reports\.register_report\(:test_report\)/)
        expect(File.exist?(report_file)).to eq(true)
      end
    end

    describe 'new_fact' do

      let(:args) do
        ['new_fact', '-n', 'test_fact']
      end

      it 'should create spec and rb file' do
        retrospec
        expect(File.exist?(File.join(module_path,'lib', 'facter', 'test_fact.rb'))).to eq(true)
        expect(File.exist?(File.join(module_path, 'spec', 'unit', 'facter', 'test_fact_spec.rb'))).to eq(true)
      end
    end

    describe 'new_type' do
      let(:type_name) do
        'type_a'
      end
      let(:type_dir) do
        File.join(module_path,'lib', 'puppet', 'type')
      end

      let(:type_spec_dir) do
        File.join(module_path, 'spec', 'unit', 'puppet', 'type')
      end

      let(:args) do
        ['new_type', '-n', type_name]
      end

      it 'should create spec and rb file' do
        retrospec
        expect(File.exist?(File.join(type_dir, "#{type_name}.rb"))).to eq(true)
        expect(File.exist?(File.join(type_spec_dir, "#{type_name}_spec.rb"))).to eq(true)
      end

      describe 'core type' do
        let(:type_name) do
          'package'
        end

        it 'should raise error' do
          retrospec
          expect(File.exist?(File.join(type_dir, "#{type_name}.rb"))).to eq(false)
          expect(File.exist?(File.join(type_spec_dir, "#{type_name}_spec.rb"))).to eq(false)
        end
      end
    end
    describe 'new_provider' do

      let(:args) do
        ['new_provider', '-n', 'pname', '--type', 'type_a']
      end

      it 'should create spec and rb file' do
        retrospec
        expect(File.exist?(File.join(module_path,'lib', 'puppet', 'provider', 'type_a', 'pname.rb'))).to eq(true)
        expect(File.exist?(File.join(module_path, 'spec', 'unit', 'puppet', 'provider', 'type_a', 'pname_spec.rb'))).to eq(true)
      end
    end

    describe 'new_function' do

      describe 'v3' do
        let(:args) do
          ['new_function', '-n', 'test_func_v3', '--type', 'v3']
        end

        it 'should create v3 function' do
          retrospec
          expect(File.exist?(File.join(module_path,'lib', 'puppet','parser', 'functions', 'test_func_v3.rb'))).to eq(true)
        end

        it 'should create v3 function spec file' do
          retrospec
          expect(File.exist?(File.join(module_path, 'spec', 'functions', 'test_func_v3_spec.rb'))).to eq(true)
        end

      end
      describe 'v4' do
        let(:args) do
          ['new_function', '-n', 'test_func_v4', '--type', 'v4']
        end

        it 'should create v4 function' do
          retrospec
          expect(File.exist?(File.join(module_path,'lib', 'puppet', 'functions', 'test_func_v4.rb'))).to eq(true)
        end

        it 'should create v4 function spec file' do
          retrospec
          expect(File.exist?(File.join(module_path, 'spec', 'functions', 'test_func_v4_spec.rb'))).to eq(true)
        end
      end
    end
  end
end
