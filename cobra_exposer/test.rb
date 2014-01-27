require_relative "../parser.rb"
require_relative "../library.rb"
require_relative "../visitor.rb"
require_relative "Generator.rb"
require_relative "LuaGenerator.rb"
require_relative "Exposer.rb"
require_relative "ExposeAST.rb"
require 'json'


library = Library.new("Test", "test")
library.addIncludePath(".")
library.addFile("test.h")
library.addFile("test_2.h")

debugging = true

parser = Parser.new(library)

visitor = VisitorImpl.new(library)
parser.parse(visitor)

exposer = Exposer.new(visitor, debugging)

Generator.new(library, exposer).generate("autogen")
LuaGenerator.new(library, exposer).generate("autogen")
