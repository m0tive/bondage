require_relative "../parser.rb"
require_relative "../library.rb"
require_relative "../visitor.rb"
require_relative "Generator.rb"
require_relative "LuaGenerator.rb"
require_relative "Exposer.rb"
require_relative "ExposeAST.rb"
require 'json'
require 'FileUtils'

DEBUGGING = true

def expose(library)
	puts "Generating '#{library.name}' library..."
	parser = Parser.new(library)

	visitor = VisitorImpl.new(library)
	parser.parse(visitor)

	exposer = Exposer.new(visitor, DEBUGGING)

	path = library.autogenPath
	unless File.directory?(path)
	  FileUtils.mkdir_p(path)
	end

	Generator.new(library, exposer).generate(path)
	LuaGenerator.new(library, exposer).generate(path)
end

example_lib = Library.new("Example", "test/example_lib")
example_lib.addIncludePath(".")
example_lib.addFile("example.h")

example_manual = Library.new("Example_manual_lib", "test/example_manual_lib")
example_manual.addIncludePath(".")

test_lib = Library.new("Test", "test")
test_lib.addIncludePath(".")
test_lib.addFile("test.h")
test_lib.addFile("test_2.h")
test_lib.addDependency(example_lib)
test_lib.addDependency(example_manual)

expose(example_lib)
expose(test_lib)