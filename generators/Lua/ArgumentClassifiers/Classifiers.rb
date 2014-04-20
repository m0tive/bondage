require_relative "IndexClassifier.rb"
require_relative "NamedClassifier.rb"

module Lua

  DEFAULT_CLASSIFIERS = {
    :index => IndexClassifier.new,
    :named => NamedClassifier.new,
  }

end
