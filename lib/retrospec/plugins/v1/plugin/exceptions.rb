module Retrospec
  module Puppet
    class ParserError < Exception
    end
    class NoManifestDirError < Exception
    end
    class InvalidModulePathError < Exception
    end
    module Generators
      class CoreTypeException < Exception
        def message
          "You cannot use a core puppet type, bad stuff will happen"
        end
      end
    end
  end
end
