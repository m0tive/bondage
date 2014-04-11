# indexes in methods
require_relative 'TestUtils.rb'
require_relative "../generators/Lua/LibraryGenerator.rb"
require_relative "../generators/Lua/FunctionGenerator.rb"

require 'test/unit'

class TestPathResolver
  def pathFor(cls)
    return "#{cls.library.name}.#{cls.name}"
  end
end


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

    libGen = Lua::LibraryGenerator.new("getFunction", TestPathResolver.new)

    libGen.generate(lib.library, exposer)

    luaPath = lib.library.autogenPath + "/lua"
    FileUtils.mkdir_p(luaPath)

    libGen.write(luaPath)

    cleanLibrary(stringLibrary)
  end

  def test_defaultArgs 
    gen = Library.new("Gen", "test/testData/Generator")
    gen.addIncludePath(".")
    gen.addFile("Generator.h")

    setupLibrary(gen)

    exposer, lib = exposeLibrary(gen)

    libGen = Lua::LibraryGenerator.new("getFunction", TestPathResolver.new)

    libGen.generate(lib.library, exposer)

    luaPath = lib.library.autogenPath + "/lua"
    FileUtils.mkdir_p(luaPath)

    libGen.write(luaPath)

    expectedGenTest = "-- Copyright me, fool. No, copying and stuff.
--
-- This file is auto generated, do not change it!
--

-- \\brief A CLASS!
--
local Gen_cls = class \"Gen\" {

  -- nil Gen:test1(number myint, number myFloat, number arg2)
  -- \\brief This funciton is a test
  -- \\param myFloat This is a float.
  -- \\param myint This is an int!
  -- \\return Returns NOTHING.
  test1 = getFunction(\"Gen\", \"test1\"),

  -- nil Gen:test2(number arg0)
  -- nil Gen:test2(number arg0, number arg1)
  -- nil Gen:test2(number arg0, number arg1, number arg2)
  -- \\brief 
  test2 = getFunction(\"Gen\", \"test2\"),

  -- nil Gen.test3(boolean arg0)
  -- number Gen.test3(boolean arg0, number arg1)
  -- number Gen.test3(boolean arg0, number arg1, boolean arg2)
  -- number Gen.test3(number arg0, number arg1)
  -- \\brief 
  test3 = getFunction(\"Gen\", \"test3\")
}

return Gen_cls"

    expectedInheritTest = "-- Copyright me, fool. No, copying and stuff.
--
-- This file is auto generated, do not change it!
--

-- \\brief 
--
local InheritTest_cls = class \"InheritTest\" {
  super = require \"Gen.Gen\",

  -- nil InheritTest:pork()
  -- \\brief 
  pork = getFunction(\"Gen\", \"pork\"),

  -- number InheritTest:pork2()
  -- \\brief 
  pork2 = getFunction(\"Gen\", \"pork2\")
}

return InheritTest_cls"

    expectedInherit2Test = "-- Copyright me, fool. No, copying and stuff.
--
-- This file is auto generated, do not change it!
--

-- \\brief 
--
local InheritTest2_cls = class \"InheritTest2\" {
  super = require \"Gen.InheritTest\",


}

return InheritTest2_cls"

    assert_equal expectedGenTest, File.read("#{luaPath}/Gen.lua")
    assert_equal expectedInheritTest, File.read("#{luaPath}/InheritTest.lua")
    assert_equal expectedInherit2Test, File.read("#{luaPath}/InheritTest2.lua")


    #cleanLibrary(gen)
  end
end

#todo
#- indexing
#- enums
#- functions in ns
#- named fns
