require 'spec_helper'

describe Retrospec::Puppet::Generators::DefinitionGenerator do

  after(:each) do
    FileUtils.rm(spec_file) if File.exists?(spec_file)
  end

  let(:generator_opts) do
    {:manifest_file => sample_file, :template_dir => retrospec_templates_path}
  end

  let(:sample_file) do
    File.join(module_path, 'manifests','one_define.pp')
  end

  let(:spec_files_path) do
    File.join(module_path, 'spec', 'defines')
  end

  let(:module_path) do
    File.join(fake_fixture_modules, 'one_resource_module')
  end

  let(:spec_file) do
    path = File.join(module_path, 'spec', 'defines', 'one_define_spec.rb')
  end

  let(:generator) do
    Retrospec::Puppet::Generators::DefinitionGenerator.new(module_path, generator_opts)
  end

  it 'should create spec file' do
    expect(generator.run).to eq(spec_file)
    expect(File.exists?(spec_file)).to eq(true)
  end

  it 'should produce correct file name' do
    expect(generator.item_spec_path).to eq(spec_file)
  end

  describe 'content' do
    let(:data) do
      "describe \"one_resource::one_define\" do\n  let(:title) do\n    \"XXreplace_meXX\"\n    \n  end\n\n  let(:params) do\n    {\n      #:one => 'one',\n    }\n  end\n  let(:facts) do\n    {\n    }\n  end\n  \n  \n  it do\n    is_expected.to contain_notify('hello')\n  end\n  \n  \nend"
    end
    it 'should generate the content' do
      expect(generator.generate_content).to eq(data)
    end
  end


  describe 'spec files' do
    let(:generated_files) do
      [File.join(spec_files_path, 'one_define_spec.rb')]
    end
    it 'should generate a bunch of files' do
      files = Retrospec::Puppet::Generators::DefinitionGenerator.generate_spec_files(module_path)
      expect(files).to eq(generated_files)
    end
  end

end
