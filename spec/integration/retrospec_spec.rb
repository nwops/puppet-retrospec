require 'spec_helper'

describe 'package' do
  let(:outer_body) do
    ['class test_case', '{', input_resource, '}']
  end
  let(:input_resource) do
    <<-EOF
    package{'httpd':
      ensure => installed,
    }
    EOF
  end

  let(:ast_obj) do
    ast(:content => outer_body.join("\n"))
  end

  describe 'single parameter' do
    it 'should create test case' do
      output = "\n\n  it do\n    is_expected.to contain_package(\"httpd\")\n        .with({\n          \"ensure\" => \"installed\",\n          })\n  end\n  "
      expect(dumper.dump(ast_obj.body.body)).to eq(output)
    end
  end

  describe 'multiple parameters' do
    let(:input_resource) do
      <<-EOF
      package{'httpd':
        ensure => installed,
        require => File['/tmp/test']
      }
      EOF
    end
    it 'should create test case' do
      output = "\n\n  it do\n    is_expected.to contain_package(\"httpd\")\n        .with({\n          \"ensure\" => \"installed\",\n          \"require\" => \"File[/tmp/test]\",\n          })\n  end\n  "
      expect(dumper.dump(ast_obj.body.body)).to eq(output)
    end
  end

  describe 'escape characters' do
    let(:input_resource) do
      <<-EOF
      $greylist_dsn = 'hello'
      file{'/tmp/test':
        ensure => present,
        content => "GREYLIST_DSN = ${greylist_dsn}\n",
      }
      EOF
    end
    it 'should create test case' do
      output = "\n\n  it do\n    is_expected.to contain_file(\"/tmp/test\")\n        .with({\n          \"ensure\" => \"present\",\n          \"content\" => \"GREYLIST_DSN = hello\\n\",\n          })\n  end\n  "
      expect(dumper.dump(ast_obj.body.body)).to eq(output)
    end


  end
end
