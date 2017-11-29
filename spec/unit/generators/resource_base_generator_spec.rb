require 'spec_helper'

describe Retrospec::Puppet::Generators::ResourceBaseGenerator do
  after(:each) do
    FileUtils.rm_rf(spec_files_path) if File.exist?(spec_files_path)
  end

  let(:generator_opts) do
    { :manifest_file => sample_file, :template_dir => retrospec_templates_path }
  end

  let(:sample_file) do
    File.join(module_path, 'manifests', 'one_define.pp')
  end

  let(:spec_files_path) do
    File.join(module_path, 'spec')
  end

  let(:module_path) do
    File.join(fake_fixture_modules, 'one_resource_module')
  end

  let(:generator) do
    Retrospec::Puppet::Generators::ResourceBaseGenerator.new(module_path, generator_opts)
  end

  let(:generated_files) do
    [File.join(spec_files_path, 'classes', 'another_resource_spec.rb'),
     File.join(spec_files_path, 'classes', 'inherits_params_spec.rb'),
     File.join(spec_files_path, 'classes', 'one_resource_spec.rb'),
     File.join(spec_files_path, 'classes', 'params_spec.rb'),
     File.join(spec_files_path, 'classes', 'array_param_spec.rb'),
     File.join(spec_files_path, 'classes', 'sub', 'settings_spec.rb'),
     File.join(spec_files_path, 'defines', 'sub', 'settings_define_spec.rb'),
     File.join(spec_files_path, 'defines', 'one_define_spec.rb')]
  end

  it 'should generate a bunch of files' do
    files = Retrospec::Puppet::Generators::ResourceBaseGenerator.generate_spec_files(module_path, generator_opts)
    expect(files).to match_array(generated_files)
  end
end
