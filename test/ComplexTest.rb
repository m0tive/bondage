require_relative 'TestUtils.rb'

require_relative "../parser/Library.rb"
require_relative "../parser/Parser.rb"
require_relative "../exposer/Exposer.rb"
require_relative "../exposer/ExposeAst.rb"
require_relative "../generators/CPP/LibraryGenerator.rb"
require_relative "../generators/Lua/LibraryGenerator.rb"

require 'test/unit'

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

  class PathResolver
    def pathFor(cls)
      return cls.name
    end
  end

  def expose(library)
    path = library.autogenPath

    exposer, visitor = exposeLibrary(library)

    CPP::LibraryGenerator.new().generate(visitor, exposer)
    luaGen = Lua::LibraryGenerator.new([], [], "getFunction", PathResolver.new)
    luaGen.generate(visitor, exposer)
    luaGen.write( library.autogenPath)
  end
end