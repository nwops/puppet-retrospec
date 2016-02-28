require_relative 'exceptions'
# load all the generators found in the generators directory
Dir.glob(File.join(File.dirname(__FILE__),'generators', '*.rb')).each do |file|
  require_relative File.join('generators', File.basename(file, '.rb'))
end
