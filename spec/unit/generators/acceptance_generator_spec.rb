require 'spec_helper'

describe Retrospec::Puppet::Generators::AcceptanceGenerator do
  after(:each) do
    FileUtils.rm_rf(spec_files_path) if File.exist?(spec_files_path)
  end

  let(:sample_file) do
    File.join(module_path, 'manifests', 'one_define.pp')
  end

  let(:generator_opts) do
    { :manifest_file => sample_file, :template_dir => retrospec_templates_path }
  end

  let(:spec_files_path) do
    File.join(module_path, 'spec', 'acceptance', 'classes')
  end

  let(:module_path) do
    File.join(fake_fixture_modules, 'one_resource_module')
  end

  let(:generator) do
    Retrospec::Puppet::Generators::AcceptanceGenerator.new(module_path, generator_opts)
  end

  let(:spec_file_contents) do
    File.read(generator.generate_spec_file)
  end

  describe 'valid context' do
    describe 'define' do
      let(:spec_file) do
        path = File.join(module_path, 'spec', 'acceptance', 'classes', 'one_define_spec.rb')
      end

      let(:sample_file) do
        File.join(module_path, 'manifests', 'one_define.pp')
      end
      let(:context) do
        generator.load_context_data
      end

      it 'should have a name' do
        expect(context.type_name).to eq('one_resource::one_define')
      end

      it 'should have a resource_type_name' do
        expect(context.resource_type_name).to eq('one_resource::one_define')
      end

      it 'should have a type' do
        expect(context.resource_type).to eq(Puppet::Pops::Model::ResourceTypeDefinition)
      end

      it 'should have parameters' do
        expect(context.parameters).to be_instance_of(String)
        expect(context.parameters.rstrip.chomp.split(',').count).to eq(1)
        # if the test returns more than the expected count there is an extra comma
        # although technically it doesn't matter
      end

      it 'should create spec file' do
        expect(generator.run).to eq(spec_file)
        expect(File.exist?(spec_file)).to eq(true)
      end

      it 'should produce correct file name' do
        expect(generator.item_spec_path).to eq(spec_file)
      end

      it 'should generate the content' do
        data = "require 'spec_helper_acceptance'\n\ndescribe 'one_resource::one_define one_resource::one_define' do\n  describe 'running puppet code' do\n    it 'should work with no errors' do\n      pp = <<-EOS\n      one_resource::one_define{'some_value':\n        # one: \"one_value\",\n\n      }\n      EOS\n\n    # Run it twice and test for idempotency\n      apply_manifest(pp, :catch_failures => true)\n      apply_manifest(pp, :catch_changes => true)\n    end\n\n  end\nend\n"
        expect(spec_file_contents).to eq(data)
      end
    end
    describe 'class' do
      let(:spec_file) do
        path = File.join(module_path, 'spec', 'acceptance', 'classes', 'another_resource_spec.rb')
      end

      let(:sample_file) do
        File.join(module_path, 'manifests', 'another_resource.pp')
      end
      let(:context) do
        generator.load_context_data
      end

      it 'should have a name' do
        expect(context.type_name).to eq('one_resource::another_resource')
      end

      it 'should have a resource_type_name' do
        expect(context.resource_type_name).to eq('class')
      end

      it 'should have a type' do
        expect(context.resource_type).to eq(Puppet::Pops::Model::HostClassDefinition)
      end

      it 'should have parameters' do
        expect(context.parameters).to be_instance_of(String)
        expect(context.parameters.split("\n").count).to eq(5)
      end

      it 'should create spec file' do
        expect(generator.run).to eq(spec_file)
        expect(File.exist?(spec_file)).to eq(true)
      end

      it 'should produce correct file name' do
        expect(generator.item_spec_path).to eq(spec_file)
      end

      it 'should generate the content' do
        data = "require 'spec_helper_acceptance'\n\ndescribe 'one_resource::another_resource class' do\n  describe 'running puppet code' do\n    it 'should work with no errors' do\n      pp = <<-EOS\n      class{'one_resource::another_resource':\n        # var1: \"value1\",\n        # var2: \"value2\",\n        # file_name: \"/tmp/test3\",\n        # config_base_path: \"/etc/hammer\",\n        # config_set: \"$one_resource::params::param1_var1\",\n\n      }\n      EOS\n\n    # Run it twice and test for idempotency\n      apply_manifest(pp, :catch_failures => true)\n      apply_manifest(pp, :catch_changes => true)\n    end\n\n  end\nend\n"
        expect(spec_file_contents).to eq(data)
      end
    end
  end

  describe 'spec files' do
    let(:generated_files) do
      [
        File.join(spec_files_path, 'another_resource_spec.rb'),
        File.join(spec_files_path, 'inherits_params_spec.rb'),
        File.join(spec_files_path, 'one_define_spec.rb'),
        File.join(spec_files_path, 'one_resource_spec.rb'),
        File.join(spec_files_path, 'sub', 'settings_spec.rb'),
        File.join(spec_files_path, 'sub', 'settings_define_spec.rb'),
        File.join(spec_files_path, 'params_spec.rb')
      ]
    end
    it 'should generate a bunch of files' do
      expect(Retrospec::Puppet::Generators::AcceptanceGenerator.generate_spec_files(module_path, generator_opts))
        .to match_array(generated_files)
    end
  end
end
