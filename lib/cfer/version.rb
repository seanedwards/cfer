module Cfer
  VERSION = "0.7.0"

  begin
    require 'semantic'
    SEMANTIC_VERSION = Semantic::Version.new(VERSION)
  rescue LoadError
  end
end
