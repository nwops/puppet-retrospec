require 'spec_helper'

describe 'type generator' do
  before :each do
    FileUtils.rm_rf(type_spec_dir)
  end

  after :each do
    FileUtils.rm_rf(File.dirname(File.dirname(generator.type_name_path))) # ensure the file does not exist
    FileUtils.rm_rf(File.dirname(generator.type_spec_dir))
  end

  before :all do
    initialize_templates
  end

  let(:type_name) do
    'vhost'
  end

  let(:type_spec_dir) do
    File.join(module_path, 'spec', 'unit', 'puppet', 'type')
  end

  let(:provider_dir) do
    File.join(module_path, 'lib', 'puppet', 'provider')
  end

  let(:type_dir) do
    File.join(module_path, 'lib', 'puppet', 'type')
  end

  let(:provider_spec_dir) do
    File.join(module_path, 'spec', 'unit', 'puppet', 'provider')
  end

  let(:module_path) do
    File.join(fixture_modules_path, 'tomcat')
  end

  let(:context) do
    { :module_path => module_path, :template_dir => retrospec_templates_path}
  end

  let(:args) do
    ['-p', 'param_one', 'param_two','-a', 'config1',
      'config2', '-n', type_name]
    end

    let(:cli_opts) do
      Retrospec::Puppet::Generators::TypeGenerator.run_cli(context, args)
    end

    let(:generator) do
      Retrospec::Puppet::Generators::TypeGenerator.new(module_path, cli_opts)
    end

    it 'returns type dir' do
      expect(generator.type_dir).to eq(type_dir)
    end

    it 'returns module path' do
      expect(generator.type_spec_dir).to eq(type_spec_dir)
    end

    it 'can return type name' do
      expect(generator.type_name).to eq('vhost')
    end

    it 'can generate a type file' do
      file_path = File.join(fixtures_path, 'modules', 'tomcat', 'lib', 'puppet', 'type', 'vhost.rb')
      expect(generator.generate_type_files).to eq(file_path)
      expect(File.exist?(File.join(generator.type_dir, "#{generator.type_name}.rb")))
    end

    it 'can generate a spec file' do
      allow(generator).to receive(:type_dir).and_return(fixtures_type_path)
      allow(generator).to receive(:type_name_path).and_return(File.join(type_dir, "#{generator.type_name}.rb"))
      files = [File.join(type_spec_dir, 'bmc_spec.rb'),
        File.join(type_spec_dir, 'bmcuser_spec.rb'),
        File.join(type_spec_dir, 'db_opatch_spec.rb')]
        expect(generator.generate_type_spec_files).to eq(files)
      end

      describe 'cli' do
        let(:context) do
          { :module_path => module_path, :template_dir => File.expand_path(File.join(ENV['HOME'], '.retrospec', 'repos', 'retrospec-puppet-templates')) }
        end

        let(:type_name) do
          'vhost'
        end

        let(:args) do
          ['-p', 'param_one', 'param_two','-a', 'prop_one',
            'prop_two', '-n', type_name]
          end

          let(:cli_opts) do
            cli_opts = Retrospec::Puppet::Generators::TypeGenerator.run_cli(context, args)
          end

          let(:generator) do
            Retrospec::Puppet::Generators::TypeGenerator.new(cli_opts[:module_path], cli_opts)
          end

          after :each do
            FileUtils.rm_rf(File.dirname(File.dirname(generator.type_name_path))) # ensure the file does not exist
            FileUtils.rm_rf(File.dirname(generator.type_spec_dir))
          end

          it 'can run the cli options' do
            # specify the parameters
            expect(cli_opts).to be_an_instance_of Hash
            expect(cli_opts[:properties]).to eq(%w(prop_one prop_two))
            expect(cli_opts[:parameters]).to eq(%w(param_one param_two))
            expect(cli_opts[:name]).to eq('vhost')
          end

          it 'generate type file with correct number of properties' do
            file = generator.generate_type_files
            require file
            t = Puppet::Type.type(:vhost)
            expect(t.properties.count). to eq(3)
          end

          context 'parameters' do
            let(:args) do
              ['-p', 'param_one', 'param_two','-a', 'prop_one',
                'prop_two', '-n', 'vhost']
              end
              it 'generate type file with correct number of parameters' do
                file = generator.generate_type_files
                require file
                t = Puppet::Type.type(:vhost)
                expect(t.parameters.count). to eq(2)
              end
            end

            context 'providers' do
              let(:args) do
                ['-p', 'param_one', 'param_two','-a', 'prop_one',
                  'prop_two', '-n', type_name, '--providers', 'default1', 'default2']
                end

                it 'generate type' do
                  file = generator.generate_type_files
                  require file
                  t = Puppet::Type.type(:vhost)
                  expect(File.exist?(file)).to eq(true)
                end

                it 'generate providers' do
                  file = generator.generate_type_files
                  p_vhost = File.join(provider_dir, 'vhost')
                  expect(File.exist?(File.join(p_vhost, 'default1.rb'))).to eq(true)
                  expect(File.exist?(File.join(p_vhost, 'default2.rb'))).to eq(true)
                  expect(generator.context.providers).to eq(%w(default1 default2))
                end
              end

              describe 'existing type' do
                let(:type_name) do
                  'package'
                end

                before :each do
                  FileUtils.rm_rf(type_spec_dir)
                  FileUtils.rm_rf(type_dir)
                end

                # it 'raise error' do
                #   expect{Retrospec::Puppet::Generators::TypeGenerator.new(module_path,
                #      cli_opts)}.to raise_exception Retrospec::Puppet::Generators::CoreTypeException
                # end
              end
            end
          end
