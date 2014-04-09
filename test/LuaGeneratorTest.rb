# indexes in methods
require_relative 'TestUtils.rb'
require_relative "../generators/Lua/LibraryGenerator.rb"
require_relative "../generators/Lua/FunctionGenerator.rb"

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

  def test_luaFunctionGenerator
    exposer, lib = exposeLibrary(@gen)

    fnGen = Lua::FunctionGenerator.new("", "getFunction")

    cls = exposer.exposedMetaData.findClass("::Gen::Gen").parsed
    assert_not_nil cls

    rootNs = lib.getExposedNamespace()
    assert_not_nil rootNs

    assert_equal 5, cls.functions.length
    assert_equal 2, rootNs.functions.length

    fn1 = cls.functions[0]
    assert_not_nil(fn1)
    assert_equal "test1", fn1.name

    fn2 = cls.functions[1]
    assert_not_nil(fn2)
    assert_equal "test2", fn2.name

    fn3 = cls.functions[2]
    assert_not_nil(fn2)
    assert_equal "test3", fn3.name

    fn4 = cls.functions[3]
    assert_not_nil(fn4)
    assert_equal "test3", fn4.name

    fn5 = cls.functions[4]
    assert_not_nil(fn5)
    assert_equal "test3", fn5.name


    fn5 = rootNs.functions[0]
    assert_not_nil(fn5)
    assert_equal "test4", fn5.name

    fn6 = rootNs.functions[1]
    assert_not_nil(fn6)
    assert_equal "test5", fn6.name

    fnGen.generate(lib.library, cls, [ fn1, fn2 ])

    assert_equal "-- nil Gen:test1(number myint, number myFloat, number arg2)
-- nil Gen:test2(number arg0)
-- nil Gen:test2(number arg0, number arg1)
-- nil Gen:test2(number arg0, number arg1, number arg2)
-- \\brief This funciton is a test
-- \\param myFloat This is a float.
-- \\param myint This is an int!
-- \\return Returns NOTHING.", fnGen.docs
    assert_equal "test1 = getFunction(\"Gen\", \"test1\")", fnGen.classDefinition
  end

  def test_stringLibGeneratorLua
    stringLibrary = Library.new("String", "test/testData/StringLibrary")
    stringLibrary.addIncludePath(".")
    stringLibrary.addFile("StringLibrary.h")
    setupLibrary(stringLibrary)

    exposer, lib = exposeLibrary(stringLibrary)

    libGen = Lua::LibraryGenerator.new("getFunction")

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

    libGen = Lua::LibraryGenerator.new("getFunction")

    libGen.generate(lib.library, exposer)

    luaPath = lib.library.autogenPath + "/lua"
    FileUtils.mkdir_p(luaPath)

    libGen.write(luaPath)

    #cleanLibrary(gen)
  end
end