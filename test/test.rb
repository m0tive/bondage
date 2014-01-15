require_relative "../parser.rb"
require_relative "../library.rb"
require_relative "../visitor.rb"

class VisitorImpl < Visitor

end 

library = Library.new("test", "test")
library.addIncludePath(".")
library.addFile("test.h")
library.addFile("test_2.h")

parser = Parser.new(library)

visitor = VisitorImpl.new
parser.parse(visitor)
