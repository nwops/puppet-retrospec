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
      output = %r{
        \n\n\s+it\sdo
        \n\s+is_expected.to\scontain_package\('httpd'\).with\(
          \n\s+ensure:\s'installed',
        \n\s+\)
        \n\s+end
        }x
      expect(dumper.dump(ast_obj.body.body)).to match(output)
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
      output = %r{
        \n\n\s+it\sdo
        \n\s+is_expected.to\scontain_package\('httpd'\).with\(
          \n\s+ensure:\s'installed',
          \n\s+require:\s'File\[/tmp/test\]',
        \n\s+\)
        \n\s+end
        }x
      expect(dumper.dump(ast_obj.body.body)).to match(output)
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
      output = %r{
        \n\n\s+it\sdo
        \n\s+is_expected.to\scontain_file\('/tmp/test'\).with\(
          \n\s+ensure:\s'present',
          \n\s+content:\s'GREYLIST_DSN\s=\shello\\n',
        \n\s+\)
        \n\s+end
        }x
      expect(dumper.dump(ast_obj.body.body)).to match(output)
    end


  end
end
