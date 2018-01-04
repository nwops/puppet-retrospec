require 'spec_helper'
require 'facter'
require 'facter/fix_installed'

describe :fix_installed, :type => :fact do
  subject(:fact) { Facter.fact(subject) }

  before :all do
    # perform any action that should be run for the entire test suite
  end

  before :each do
    # perform any action that should be run before every test
    Facter.clear
    # This will mock the facts that confine uses to limit facts running under certain conditions
    allow(Facter.fact(:kernel)).to receive(:value).and_return("windows")
  
  end

  it 'should return a value' do
    expect(Facter.fact(:fix_installed).value).to eq('value123')  #<-- change the value to match your expectation
  end
end
