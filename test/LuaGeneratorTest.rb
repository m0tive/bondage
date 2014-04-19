# indexes in methods
require_relative 'TestUtils.rb'
require_relative "../generators/Lua/LibraryGenerator.rb"
require_relative "../generators/Lua/Function/Generator.rb"
require_relative "../generators/Lua/EnumGenerator.rb"
require_relative "../generators/Lua/ArgumentClassifiers/Classifiers.rb"

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

    @luaFuncs = Library.new("LuaFunctions", "test/testData/LuaFunctions")
    @luaFuncs.addIncludePath(".")
    @luaFuncs.addFile("LuaFunctions.h")

    @props = Library.new("Properties", "test/testData/Properties")
    @props.addIncludePath(".")
    @props.addFile("Properties.h")
    
    setupLibrary(@gen)
    setupLibrary(@luaFuncs)
    setupLibrary(@props)
  end

  def teardown
    cleanLibrary(@props)
    cleanLibrary(@luaFuncs)
    cleanLibrary(@gen)
  end

  def test_luaFunctionGenerator
    exposer, lib = exposeLibrary(@gen)

    fnGen = Lua::Function::Generator.new(nil, "", "getFunction")

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

    assert_equal "-- nil Gen:test1(number myint, number myFloat, number arg3)
-- nil Gen:test2(number arg1)
-- nil Gen:test2(number arg1, number arg2)
-- nil Gen:test2(number arg1, number arg2, number arg3)
-- \\brief This funciton is a test
-- \\param myFloat This is a float.
-- \\param myint This is an int!", fnGen.docs
    assert_equal "getFunction(\"Gen\", \"Gen\", \"test1\")", fnGen.bind
  end

  def test_stringLibGeneratorLua
    stringLibrary = Library.new("String", "test/testData/StringLibrary")
    stringLibrary.addIncludePath(".")
    stringLibrary.addFile("StringLibrary.h")
    setupLibrary(stringLibrary)

    exposer, lib = exposeLibrary(stringLibrary)

    libGen = Lua::LibraryGenerator.new([], [], "getFunction", TestPathResolver.new)

    libGen.generate(lib, exposer)

    luaPath = lib.library.autogenPath + "/lua"
    FileUtils.mkdir_p(luaPath)

    libGen.write(luaPath)

    cleanLibrary(stringLibrary)
  end

  def test_enumTest
    exposer, lib = exposeLibrary(@gen)

    cls = exposer.exposedMetaData.findClass("::Gen::InheritTest2").parsed
    assert_not_nil cls

    assert_equal 1, cls.enums.length
  
    enumGen = Lua::EnumGenerator.new("")

    enumGen.generate(cls)

    assert_equal 1, enumGen.enums.length

    assert_equal "MyEnum = {\n  test = 0,\n  test2 = 2,\n  test3 = 3,\n}", enumGen.enums[0]
  end

  def test_genTest
    exposer, lib = exposeLibrary(@gen)

    libGen = Lua::LibraryGenerator.new([], [], "getFunction", TestPathResolver.new)

    libGen.generate(lib, exposer)

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

  -- nil Gen:test1(number myint, number myFloat, number arg3)
  -- \\brief This funciton is a test
  -- \\param myFloat This is a float.
  -- \\param myint This is an int!
  test1 = getFunction(\"Gen\", \"Gen\", \"test1\"),

  -- nil Gen:test2(number arg1)
  -- nil Gen:test2(number arg1, number arg2)
  -- nil Gen:test2(number arg1, number arg2, number arg3)
  -- \\brief 
  test2 = getFunction(\"Gen\", \"Gen\", \"test2\"),

  -- nil Gen.test3(boolean arg1)
  -- number Gen.test3(boolean arg1, number arg2)
  -- number Gen.test3(boolean arg1, number arg2, boolean arg3)
  -- number Gen.test3(number arg1, number arg2)
  -- \\brief 
  test3 = getFunction(\"Gen\", \"Gen\", \"test3\")
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
  pork = getFunction(\"Gen\", \"InheritTest\", \"pork\"),

  -- number InheritTest:pork2()
  -- \\brief 
  pork2 = getFunction(\"Gen\", \"InheritTest\", \"pork2\")
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

  MyEnum = {
    test = 0,
    test2 = 2,
    test3 = 3,
  },


}

return InheritTest2_cls"

    libraryTest = "-- Copyright me, fool. No, copying and stuff.
--
-- This file is auto generated, do not change it!
--

local Gen = {
  Gen = require(\"Gen.Gen\"),

  InheritTest = require(\"Gen.InheritTest\"),

  InheritTest2 = require(\"Gen.InheritTest2\"),

  MultipleReturnGen = require(\"Gen.MultipleReturnGen\"),

  CtorGen = require(\"Gen.CtorGen\"),

  GlbEnum = {
    A = 0,
    B = 1,
  },

  -- number Gen.test4(boolean a, boolean b)
  -- \\brief 
  test4 = getFunction(\"Gen\", \"\", \"test4\"),

  -- number Gen.test5(boolean a, boolean b)
  -- number Gen.test5(boolean a, boolean b, number arg3)
  -- \\brief 
  test5 = getFunction(\"Gen\", \"\", \"test5\")
}

return Gen"

    assert_equal expectedGenTest, File.read("#{luaPath}/Gen.lua")
    assert_equal expectedInheritTest, File.read("#{luaPath}/InheritTest.lua")
    assert_equal expectedInherit2Test, File.read("#{luaPath}/InheritTest2.lua")
    assert_equal libraryTest, File.read("#{luaPath}/GenLibrary.lua")
  end

  def test_luaIndexedFunctionGeneration
    exposer, lib = exposeLibrary(@luaFuncs)

    clsMetaData = exposer.exposedMetaData.findClass("::LuaFunctions::TestClass")
    cls = clsMetaData.parsed
    assert_not_nil cls

    rootNs = lib.getExposedNamespace()
    assert_not_nil rootNs

    assert_equal 4, cls.functions.length
    assert_equal 1, rootNs.functions.length

    fnGen = Lua::Function::Generator.new(Lua::DEFAULT_CLASSIFIERS, "", "get")

    fnGen.generate(lib.library, cls, cls.functions)
    assert_equal "get(\"LuaFunctions\", \"TestClass\", \"luaSample\")", fnGen.bind
    fnGen.generate(lib.library, rootNs, rootNs.functions)


    clsMetaData2 = exposer.exposedMetaData.findClass("::LuaFunctions::TestClassIndexed")
    cls2 = clsMetaData2.parsed
    assert_not_nil cls2

    firstGroup = [ cls2.functions[0], cls2.functions[1], cls2.functions[2], cls2.functions[3] ]
    fnGen.generate(lib.library, cls2, firstGroup)
    assert_equal :index, fnGen.returnClassifier(0)
    assert_equal :index, fnGen.returnClassifier(1)
    assert_equal :index, fnGen.argumentClassifier(0)
    assert_equal :none, fnGen.argumentClassifier(1)
    assert_equal :none, fnGen.argumentClassifier(2)
    assert_equal :index, fnGen.argumentClassifier(3)

    overloads = fnGen.overloads
    assert_not_nil overloads[0]
    assert_equal 1, overloads[0].returnTypes[0].length
    assert_equal false, overloads[0].static
    assert_not_nil overloads[1]
    assert_equal 1, overloads[1].returnTypes[0].length
    assert_equal false, overloads[1].static
    assert_not_nil overloads[2]
    assert_equal 1, overloads[2].returnTypes[0].length
    assert_equal false, overloads[2].static
    assert_nil overloads[3]
    assert_not_nil overloads[4]
    assert_equal 2, overloads[4].returnTypes[0].length
    assert_equal true, overloads[4].static

    assert_equal "-- number TestClassIndexed:luaSample()
-- number TestClassIndexed:luaSample(number idx)
-- number TestClassIndexed:luaSample(number idx, number arg2)
-- number, number TestClassIndexed.luaSample(number idx, number a, number b, number idx3)
-- \\brief sample
-- \\param idx the Index
-- \\param idx2 the Index2
-- \\param idx3 the Index2", fnGen.docs

    assert_equal "local TestClassIndexed_luaSample_wrapper_fwd = get(\"LuaFunctions\", \"TestClassIndexed\", \"\")
local TestClassIndexed_luaSample_wrapper = function(...)
  local argCount = select(\"#\")
  if 1 == argCount then
    local ret0 = fwdName()
    return (ret0-1)
  end
  if 2 == argCount then
    local ret0 = fwdName((select(0, ...)-1))
    return (ret0-1)
  end
  if 3 == argCount then
    local ret0 = fwdName((select(0, ...)-1), select(1, ...))
    return (ret0-1)
  end
  if 4 == argCount then
    local ret0, ret1 = fwdName((select(0, ...)-1), select(1, ...), select(2, ...), (select(3, ...)-1))
    return (ret0-1), (ret1-1)
  end
end", fnGen.wrapper


    secondGroup = [ cls2.functions[4] ]
    fnGen.generate(lib.library, cls2, secondGroup)
    assert_equal :index, fnGen.returnClassifier(0)

    assert_equal "-- LuaFunctions::TestClassIndexed TestClassIndexed:luaSample2()
-- \\brief [index]", fnGen.docs

    assert_equal "local TestClassIndexed_luaSample2_wrapper_fwd = get(\"LuaFunctions\", \"TestClassIndexed\", \"\")
local TestClassIndexed_luaSample2_wrapper = function(...)
  local argCount = select(\"#\")
  if 1 == argCount then
    local ret0 = fwdName()
    return from_native(ret0)
  end
end", fnGen.wrapper

    nsGroup = [ rootNs.functions[0] ]
    fnGen.generate(lib.library, rootNs, nsGroup)
    assert_equal :none, fnGen.returnClassifier(0)

    assert_equal "-- nil LuaFunctions.testFunction()
-- \\brief ", fnGen.docs

    assert_equal "", fnGen.wrapper

    clsGen = Lua::ClassGenerator.new([], Lua::DEFAULT_CLASSIFIERS, "", "get")

    clsGen.generate(lib.library, exposer, TestPathResolver.new, clsMetaData, "var")

    assert_equal %{-- \\brief 
--
local var = class "TestClass" {

-- nil TestClass:luaSample()
-- nil TestClass:luaSample(number arg1)
-- nil TestClass:luaSample(number arg1)
-- nil TestClass:luaSample(number arg1, number arg2)
-- \\brief 
luaSample = get("LuaFunctions", "TestClass", "luaSample")
}}, clsGen.classDefinition

    clsGen.generate(lib.library, exposer, TestPathResolver.new, clsMetaData2, "var")

    assert_equal %{local TestClassIndexed_luaSample_wrapper_fwd = get("LuaFunctions", "TestClassIndexed", "")
local TestClassIndexed_luaSample_wrapper = function(...)
  local argCount = select("#")
  if 1 == argCount then
    local ret0 = fwdName()
    return (ret0-1)
  end
  if 2 == argCount then
    local ret0 = fwdName((select(0, ...)-1))
    return (ret0-1)
  end
  if 3 == argCount then
    local ret0 = fwdName((select(0, ...)-1), select(1, ...))
    return (ret0-1)
  end
end

local TestClassIndexed_luaSample2_wrapper_fwd = get("LuaFunctions", "TestClassIndexed", "")
local TestClassIndexed_luaSample2_wrapper = function(...)
  local argCount = select("#")
  if 1 == argCount then
    local ret0 = fwdName()
    return from_native(ret0)
  end
end

-- \\brief 
--
local var = class "TestClassIndexed" {

-- number TestClassIndexed:luaSample()
-- number TestClassIndexed:luaSample(number idx)
-- number TestClassIndexed:luaSample(number idx, number arg2)
-- \\brief sample
-- \\param idx the Index
luaSample = TestClassIndexed_luaSample_wrapper,

-- LuaFunctions::TestClassIndexed TestClassIndexed:luaSample2()
-- \\brief [index]
luaSample2 = TestClassIndexed_luaSample2_wrapper
}}, clsGen.classDefinition

  end


  def test_properties
    exposer, lib = exposeLibrary(@props, true)

  end
end

#todo
#- named fns
#- properties
#- signals?
