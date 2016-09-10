module Cfer
  VERSION = "0.5.0-rc2"

  begin
    require 'semantic'
    SEMANTIC_VERSION = Semantic::Version.new(VERSION)
  rescue LoadError
  end
end
