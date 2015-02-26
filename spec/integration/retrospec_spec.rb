require 'spec_helper'

describe "variable_store" do

  # after :all do
  #   # enabling the removal slows down tests, but from time to time we may need to
  #   FileUtils.rm_rf(fixture_modules_path) if ENV['RETROSPEC_CLEAN_UP_TEST_MODULES'] =~ /true/
  # end
  #
  # before :all do
  #   #enabling the removal of real modules slows down tests, but from time to time we may need to
  #   FileUtils.rm_rf(fixture_modules_path) if ENV['RETROSPEC_CLEAN_UP_TEST_MODULES'] =~ /true/
  #   install_module('puppetlabs-tomcat')
  #   @path = File.join(fixture_modules_path, 'tomcat')
  #   @bin_path = File.expand_path(File.join('/Users/cosman/bodeco/puppet-retrospec', 'bin', 'retrospec'))
  #
  # end
  #
  # before :each do
  #   clean_up_spec_dir("#{@path}/spec")
  #   @opts = {:module_path => @path, :enable_beaker_tests => false,
  #            :enable_user_templates => false, :template_dir => nil }
  # end
  #
  # it 'should create files without error' do
  #   `#{@bin_path} #{@path}`
  #   expect(File.exists?(File.join(@path, 'Gemfile'))).to eq(true)
  #   expect(File.exists?(File.join(@path, 'Rakefile'))).to eq(true)
  #   expect(File.exists?(File.join(@path, 'spec', 'shared_contexts.rb'))).to eq(true)
  #   expect(File.exists?(File.join(@path, '.fixtures.yml'))).to eq(true)
  #   expect(File.exists?(File.join(@path, 'spec','classes','tomcat_spec.rb'))).to eq(true)
  #   #clean_up_spec_dir(@path)
  #
  # end

end
