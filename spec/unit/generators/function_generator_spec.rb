require 'spec_helper'

describe 'function_generator' do
  before :each do
    FileUtils.rm_rf(generator.v3_spec_dir)
    FileUtils.rm_rf(generator.v4_spec_dir)
    FileUtils.rm_rf(function_path)
  end

  before :all do
    initialize_templates
  end

  let(:function_path) do
    File.join(module_path, 'lib', 'puppet', 'parser', 'functions', "#{function_name}.rb")
  end

  let(:module_path) do
    sample_module_path
  end

  let(:context) do
    { :module_path => module_path,
      :template_dir => template_dir }
  end

  let(:template_dir) do
    retrospec_templates_path
  end

  let(:native_function_file) do
    File.join(fixtures_path, 'functions', 'abs.pp')
  end

  let(:function_name) do
    'awesome_parser'
  end

  let(:type_name) do
    'v4'
  end

  let(:return_type) do
    'rvalue'
  end

  let(:cli_opts) do
    Retrospec::Puppet::Generators::FunctionGenerator.run_cli(context, opts)
  end

  let(:generator) do
    Retrospec::Puppet::Generators::FunctionGenerator.new(module_path, cli_opts)
  end

  describe 'ruby unit tests' do
    let(:opts) do
      ['-n', function_name, '-r', return_type, '-t', type_name, '-u', 'ruby']
    end

    it 'contain template dir' do
      expect(generator.template_dir).to match /templates\/functions/
    end

    it 'returns function name' do
      expect(generator.function_name).to eq(function_name)
    end

    it 'generate spec files' do
      files = [File.join(generator.v3_spec_dir, 'defined_spec.rb'),
               File.join(generator.v3_spec_dir, 'sha1_spec.rb'),
               File.join(generator.v4_spec_dir, 'reduce_spec.rb'),
               File.join(generator.v4_spec_dir, 'awesome_parser_spec.rb')]
      expect(generator.generate_spec_files).to match_array(files)
    end

    it 'returns found function files' do
      files = [
        File.join(module_path, 'lib', 'puppet', 'functions', 'awesome_parser.rb'),
        File.join(module_path, 'lib', 'puppet', 'functions', 'reduce.rb'),
        File.join(module_path, 'lib', 'puppet', 'parser', 'functions', 'bad_sha1.rb'),
        File.join(module_path, 'lib', 'puppet', 'parser', 'functions', 'defined.rb'),
        File.join(module_path, 'lib', 'puppet', 'parser', 'functions', 'sha1.rb')
      ]
      expect(generator.discovered_functions).to match_array(files)
    end

    describe 'v3' do
      let(:type_name) do
        'v3'
      end

      let(:function_path) do
        File.join(module_path, 'lib', 'puppet', 'parser', 'functions', "#{function_name}.rb")
      end

      it 'returns function directory' do
        path = File.join(module_path, 'lib', 'puppet', 'parser', 'functions')
        expect(generator.function_dir).to eq(path)
      end

      it 'returns function path' do
        path = File.join(module_path, 'lib', 'puppet', 'parser', 'functions', "#{function_name}.rb")
        expect(generator.function_path).to eq(path)
      end

      it 'generate function file' do
        expect(generator.generate_function_file).to eq(function_path)
      end

      it 'returns spec file directory' do
        path = File.join(module_path, 'spec', 'unit', 'puppet', 'parser', 'functions')
        expect(generator.spec_file_dir).to eq(path)
      end

      it 'return v3 template path' do
        allow(generator).to receive(:function_type).and_return('v3')
        path = File.join(gem_template_path, 'functions', 'v3')
        expect(generator.template_dir).to match(/functions\/v3/)
      end

      it 'return true when v3 function' do
        path = File.join(module_path, 'lib', 'puppet', 'parser', 'functions', 'bad_sha1.rb')
        expect(generator.v3_function?(path)).to eq true
      end

      it 'return v3 template path when context is changed' do
        generator.template_dir  # uses v4
        generator.context.function_type = 'v3'
        expect(generator.template_dir).to match(/functions\/v3/)
      end

      it 'return false when v3 function' do
        path = File.join(module_path, 'lib', 'puppet', 'parser', 'functions', 'reduce.rb')
        expect(generator.v4_function?(path)).to eq false
        expect(generator.native_function?(path)).to eq false
      end
    end

    describe 'v4' do
      let(:type_name) do
        'v4'
      end

      let(:function_path) do
        File.join(module_path, 'lib', 'puppet', 'functions', "#{function_name}.rb")
      end

      it 'return false when v4 function' do
        path = File.join(module_path, 'lib', 'puppet', 'functions', 'reduce.rb')
        expect(generator.v3_function?(path)).to eq false
        expect(generator.native_function?(path)).to eq false
      end

      it 'return v4 template path' do
        allow(generator).to receive(:function_type).and_return('v4')
        expect(generator.template_dir).to match(/functions\/v4/)
      end

      it 'return v4 template path when context is changed' do
        generator.template_dir
        generator.context.function_type = 'v4'
        expect(generator.template_dir).to match(/functions\/v4/)
      end

      it 'returns function path' do
        path = File.join(module_path, 'lib', 'puppet', 'functions', "#{function_name}.rb")
        expect(generator.function_path).to eq(path)
      end

      it 'returns spec file directory' do
        path = File.join(module_path, 'spec', 'unit', 'puppet', 'functions')
        expect(generator.spec_file_dir).to eq(path)
      end

      it 'returns function directory' do
        path = File.join(module_path, 'lib', 'puppet', 'functions')
        expect(generator.function_dir).to eq(path)
      end

      it 'generate function file' do
        expect(generator.generate_function_file).to eq(function_path)
      end
    end
  end

  describe 'rspec unit tests' do
    let(:opts) do
      ['-n', function_name, '-r', 'return_type', '-t', type_name, '-u', 'rspec']
    end

    it 'contain template dir' do
      expect(generator.template_dir).to match /templates\/functions/
    end

    it 'returns function name' do
      expect(generator.function_name).to eq(function_name)
    end

    it 'generate spec files' do
      files = [File.join(generator.v3_spec_dir, 'defined_spec.rb'),
               File.join(generator.v3_spec_dir, 'sha1_spec.rb'),
               File.join(generator.v4_spec_dir, 'reduce_spec.rb'),
               File.join(generator.v4_spec_dir, 'awesome_parser_spec.rb')]
      expect(generator.generate_spec_files).to match_array(files)
    end

    it 'returns found function files' do
      files = [
        File.join(module_path, 'lib', 'puppet', 'functions', 'awesome_parser.rb'),
        File.join(module_path, 'lib', 'puppet', 'functions', 'reduce.rb'),
        File.join(module_path, 'lib', 'puppet', 'parser', 'functions', 'bad_sha1.rb'),
        File.join(module_path, 'lib', 'puppet', 'parser', 'functions', 'defined.rb'),
        File.join(module_path, 'lib', 'puppet', 'parser', 'functions', 'sha1.rb')
      ]
      expect(generator.discovered_functions).to match_array(files)
    end

    describe 'v3' do
      let(:type_name) do
        'v3'
      end

      let(:function_path) do
        File.join(module_path, 'lib', 'puppet', 'parser', 'functions', "#{function_name}.rb")
      end

      it 'returns function directory' do
        path = File.join(module_path, 'lib', 'puppet', 'parser', 'functions')
        expect(generator.function_dir).to eq(path)
      end

      it 'returns function path' do
        path = File.join(module_path, 'lib', 'puppet', 'parser', 'functions', "#{function_name}.rb")
        expect(generator.function_path).to eq(path)
      end

      it 'generate function file' do
        expect(generator.generate_function_file).to eq(function_path)
      end

      it 'returns spec file directory' do
        path = File.join(module_path, 'spec', 'functions')
        expect(generator.spec_file_dir).to eq(path)
      end

      it 'return v3 template path' do
        allow(generator).to receive(:function_type).and_return('v3')
        path = File.join(gem_template_path, 'functions', 'v3')
        expect(generator.template_dir).to match(/functions\/v3/)
      end

      it 'return true when v3 function' do
        path = File.join(module_path, 'lib', 'puppet', 'parser', 'functions', 'bad_sha1.rb')
        expect(generator.v3_function?(path)).to eq true
      end

      it 'return v3 template path when context is changed' do
        generator.template_dir  # uses v4
        generator.context.function_type = 'v3'
        expect(generator.template_dir).to match(/functions\/v3/)
      end
    end

    describe 'v4' do
      let(:type_name) do
        'v4'
      end

      let(:function_path) do
        File.join(module_path, 'lib', 'puppet', 'functions', "#{function_name}.rb")
      end

      it 'return false when v4 function' do
        path = File.join(module_path, 'lib', 'puppet', 'functions', 'reduce.rb')
        expect(generator.v3_function?(path)).to eq false
      end

      it 'return v4 template path' do
        allow(generator).to receive(:function_type).and_return('v4')
        expect(generator.template_dir).to match(/functions\/v4/)
      end

      it 'return v4 template path when context is changed' do
        generator.template_dir
        generator.context.function_type = 'v4'
        expect(generator.template_dir).to match(/functions\/v4/)
      end

      it 'returns function path' do
        path = File.join(module_path, 'lib', 'puppet', 'functions', "#{function_name}.rb")
        expect(generator.function_path).to eq(path)
      end

      it 'returns spec file directory' do
        path = File.join(module_path, 'spec', 'functions')
        expect(generator.spec_file_dir).to eq(path)
      end

      it 'returns function directory' do
        path = File.join(module_path, 'lib', 'puppet', 'functions')
        expect(generator.function_dir).to eq(path)
      end

      it 'generate function file' do
        expect(generator.generate_function_file).to eq(function_path)
      end
    end

    describe 'native' do
      let(:type_name) do
        'native'
      end

      let(:function_path) do
        File.join(module_path, 'functions', "#{function_name}.pp")
      end

      it 'return false when native function' do
        path = File.join(module_path, 'functions', 'reduce.pp')
        expect(generator.v3_function?(path)).to eq false
        expect(generator.v4_function?(path)).to eq false
      end

      it 'return native template path' do
        allow(generator).to receive(:function_type).and_return('native')
        expect(generator.template_dir).to match(/functions\/native/)
      end

      it 'return v4 template path when context is changed' do
        generator.template_dir
        generator.context.function_type = 'native'
        expect(generator.template_dir).to match(/functions\/native/)
      end

      it 'returns function path' do
        path = File.join(module_path, 'functions', "#{function_name}.pp")
        expect(generator.function_path).to eq(path)
      end

      it 'returns spec file directory' do
        path = File.join(module_path, 'spec', 'functions')
        expect(generator.spec_file_dir).to eq(path)
      end

      it 'returns function directory' do
        path = File.join(module_path, 'functions')
        expect(generator.function_dir).to eq(path)
      end

      it 'generate spec file' do
        allow(generator).to receive(:discovered_functions).and_return([native_function_file])
        path = File.join(generator.module_path, 'spec', 'functions', 'abs_spec.rb')
        expect(generator.generate_spec_files).to eq([path])
      end

      it 'generate spec file content' do
        allow(generator).to receive(:discovered_functions).and_return([native_function_file])
        path = File.join(generator.module_path, 'spec', 'functions', 'abs_spec.rb')
        expect(generator.generate_spec_files).to eq([path])
        test_file_content = File.read(path)
        result = "require 'spec_helper'\n\ndescribe 'abs' do\n  let(:x) do\n    'some_value_goes_here'\n  end\n  it { is_expected.to run.with_params(x).and_return('some_value') }\nend\n"
        expect(test_file_content).to eq(result)
      end

      it 'generate function file path' do
        file = File.join(generator.template_dir, 'function_template.pp.retrospec.erb')
        expect(generator.function_file_path).to eq file
      end
    end
  end
end
