require_relative 'TestUtils.rb'

require_relative "../parser/Library.rb"
require_relative "../parser/Parser.rb"
require_relative "../exposer/Exposer.rb"
require_relative "../exposer/ExposeAst.rb"
require_relative "../exposer/Generator.rb"
require_relative "../exposer/LuaGenerator.rb"

require 'test/unit'

DEBUGGING = false

class TestComplex < Test::Unit::TestCase
  def setup		
    @example_lib = Library.new("Example", "test/testData/Complex/example_lib")
    @example_lib.addIncludePath(".")
    @example_lib.addFile("example.h")

    @example_manual = Library.new("Example_manual_lib", "test/testData/Complex/example_manual_lib")
    @example_manual.addIncludePath(".")

    @test_lib = Library.new("Test", "test/testData/Complex/test")
    @test_lib.addIncludePath(".")
    @test_lib.addFile("test.h")
    @test_lib.addFile("test_2.h")
    @test_lib.addDependency(@example_lib)
    @test_lib.addDependency(@example_manual)

    setupLibrary(@test_lib)
    setupLibrary(@example_lib)
  end

  def teardown
    cleanLibrary(@test_lib)
    cleanLibrary(@example_lib)
	end

  def test_complex
    expose(@example_lib)
    expose(@test_lib)
	end

  def expose(library)
    puts "Generating '#{library.name}' library... into '#{library.autogenPath}'"
    path = library.autogenPath

    parser = Parser.new(library, DEBUGGING)

    visitor = ExposeAstVisitor.new(library)
    parser.parse(visitor)

    exposer = Exposer.new(visitor, DEBUGGING)

    Generator.new(library, exposer).generate(path)
    LuaGenerator.new(library, exposer).generate(path)
  end
end