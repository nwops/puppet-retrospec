require 'fileutils'

class Helpers

  # @return [String] - the name of the module
  def self.get_module_name
    module_name = nil
    Dir['manifests/*.pp'].entries.each do |manifest|
      module_name = get_module_name_from_file(manifest)
      break unless module_name.nil?
    end
    module_name
  end

  # @param file [String] - the initial manifest file that contains the name of the module
  # @return [String] - the name of the module
  def self.get_module_name_from_file(file)
    p = Puppet::Parser::Lexer.new
    module_name = nil
    p.string = File.read(file)
    tokens = p.fullscan

    i = tokens.index { |token| [:CLASS, :DEFINE].include? token.first }
    module_name = tokens[i + 1].last[:value].split('::').first unless i.nil?

    module_name
  end

  # @param dir [String] - the module dir
  # @return [Boolean] - true if the module contains a manifests directory
  def self.is_module_dir?(dir)
    Dir[File.join(dir, '*')].entries.include? 'manifests'
  end
end
