require 'spec_helper'
describe "one_resource" do
  let(:params) do
    {
    }
  end
  let(:facts) do {
    }
  end
  
  
  it do
    is_expected.to contain_file('/tmp/test')
      .with({
        "ensure" => present,
        
      })
  end
  
  
end
