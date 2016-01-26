require 'digest/sha1'

Puppet::Parser::Functions::newfunction(:bad_sha1, :type => :rvalue, :arity => 1, :doc => "Returns a SHA1 hash value from a provided string.") do |args|
  \crap
  value = Digest::SHA1.hexdigest(args[0])
end