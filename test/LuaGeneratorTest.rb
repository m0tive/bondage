# indexes in methods
require_relative 'TestUtils.rb'
require_relative "../generators/LuaGenerator.rb"

require 'test/unit'


class TestGenerator < Test::Unit::TestCase
  def setup
    @gen = Library.new("Gen", "test/testData/Generator")
    @gen.addIncludePath(".")
    @gen.addFile("Generator.h")
    
    setupLibrary(@gen)
  end

  def teardown
  end

  def test_stringLibGenerator 
    stringLibrary = Library.new("String", "test/testData/StringLibrary")
    stringLibrary.addIncludePath(".")
    stringLibrary.addFile("StringLibrary.h")
    setupLibrary(stringLibrary)

    exposer, lib = exposeLibrary(stringLibrary)

    libGen = LuaLibraryGenerator.new()

    libGen.generate(lib.library, exposer)

    luaPath = lib.library.autogenPath + "/lua"
    FileUtils.mkdir_p(luaPath)

    libGen.write(luaPath)

    #cleanLibrary(stringLibrary)
  end

  def test_defaultArgs 
    gen = Library.new("Gen", "test/testData/Generator")
    gen.addIncludePath(".")
    gen.addFile("Generator.h")

    setupLibrary(gen)

    exposer, lib = exposeLibrary(gen)

    libGen = LuaLibraryGenerator.new()

    libGen.generate(lib.library, exposer)

    luaPath = lib.library.autogenPath + "/lua"
    FileUtils.mkdir_p(luaPath)

    libGen.write(luaPath)
    
    #cleanLibrary(gen)
  end
end