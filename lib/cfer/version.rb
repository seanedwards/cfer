module Cfer
  VERSION = "0.6.2"

  begin
    require 'semantic'
    SEMANTIC_VERSION = Semantic::Version.new(VERSION)
  rescue LoadError
  end
end
