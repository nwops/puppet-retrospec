require 'spec_helper'
describe "one_resource::another_resource" do
  let(:params) do
    {
      #:var1 => 'value1',
      #:var2 => 'value2',
      #:file_name => '/tmp/test3',
      #:config_base_path => '/etc/hammer',
      #:config_set => $one_resource::params::param1_var1,
    }
  end
  let(:facts) do {
    $one_resource::params::param1_var1 => $one_resource::params::param1_var1,
    $param1_var1 => $one_resource::params::param1_var1,
    }
  end
  
  
  
  
  
  
  it do
    is_expected.to contain_file('/tmp/test2')
      .with({
        "ensure" => present,
        
      })
  end
  
  
  it do
    is_expected.to contain_file('/tmp/test3')
      .with({
        "ensure" => present,
        "content" => '' '/tmp/test3' '/test3183/' 'oohhhh' '',
        
      })
  end
  
  context '' do
    
    
    
    it do
      is_expected.to contain_file(["''", ["'/tmp/test3'"], "'/3'"])
        .with({
          "ensure" => present,
          
        })
    end
    
    
  end
  
end
