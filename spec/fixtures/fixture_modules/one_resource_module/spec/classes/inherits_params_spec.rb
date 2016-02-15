require 'spec_helper'
describe "one_resource::inherits_params" do
  let(:params) do
    {
      #:some_var => $one_resource::params::var1,
    }
  end
  let(:facts) do {
    $one_resource::params::var1 => $one_resource::params::var1,
    $var1 => $one_resource::params::var1,
    :osfamily => $::osfamily,
    }
  end
  
  
  
end
