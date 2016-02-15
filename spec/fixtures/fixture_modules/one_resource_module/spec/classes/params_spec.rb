require 'spec_helper'
describe "one_resource::params" do
  let(:params) do
    {
      #:param1_var1 => 'param1_value',
    }
  end
  let(:facts) do {
    :osfamily => $::osfamily,
    }
  end
  
  
  
  describe '::osfamily' do
    let(:params) do
      params.merge({})
    end
    let(:facts) do
    
    end
    context 'windows' do
      
      
      
    end
    context 'redhat' do
      
      
      
    end
    context :default do
      
      
      
    end
  
end
