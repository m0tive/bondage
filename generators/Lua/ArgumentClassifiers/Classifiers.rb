require_relative "IndexClassifier.rb"

module Lua

  DEFAULT_CLASSIFIERS = {
    :index => IndexClassifier.new 
  }

end
