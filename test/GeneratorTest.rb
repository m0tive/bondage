require_relative 'TestUtils.rb'

require_relative "../parser/Library.rb"
require_relative "../parser/Parser.rb"
require_relative "../exposer/ExposeAst.rb"
require_relative "../generators/Generator.rb"

require 'test/unit'


class TestGenerator < Test::Unit::TestCase
  def setup
    @gen = Library.new("Gen", "test/testData/Generator")
    @gen.addIncludePath(".")
    @gen.addFile("Generator.h")
    
    setupLibrary(@gen)
  end

  def teardown
    cleanLibrary(@gen)
  end

  def test_functionGenerator
    exposer, lib = exposeLibrary(@gen)

    fnGen = FunctionGenerator.new("")

    assert_equal 2, exposer.exposedMetaData.fullTypes.length

    rootNs = lib.getExposedNamespace()
    assert_not_nil rootNs

    cls = exposer.exposedMetaData.findClass("::Gen::Gen").parsed
    assert_not_nil cls

    multiReturnCls = exposer.exposedMetaData.findClass("::Gen::MultipleReturnGen").parsed
    assert_not_nil multiReturnCls

    assert_equal 4, cls.functions.length
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

    fn5 = rootNs.functions[0]
    assert_not_nil(fn5)
    assert_equal "test4", fn5.name

    fn6 = rootNs.functions[1]
    assert_not_nil(fn6)
    assert_equal "test5", fn6.name

    assert_equal false, fnGen.needsSpecialBinding(fn1)
    assert_equal true, fnGen.needsSpecialBinding(fn2)

    assert_equal false, fnGen.needsSpecialBinding(fn3)
    assert_equal true, fnGen.needsSpecialBinding(fn4)

    assert_equal false, fnGen.needsSpecialBinding(fn5)
    assert_equal true, fnGen.needsSpecialBinding(fn6)

    fnGen.generate(cls, [ fn1 ])
    assert_equal "cobra::function_builder::build<void(::Gen::Gen::*)(int, float, double), &::Gen::Gen::test1>(\"test1\")", fnGen.bind
    assert_equal [], fnGen.extraFunctions


    fnGen.generate(cls, [ fn2 ])
    assert_equal "cobra::function_builder::build_overloaded<
  cobra::function_builder::build_call<void(::Gen::Gen::*)(int), &Gen_Gen_test2_overload1>,
  cobra::function_builder::build_call<void(::Gen::Gen::*)(int, float), &Gen_Gen_test2_overload2>,
  cobra::function_builder::build_call<void(::Gen::Gen::*)(int, float, double), &::Gen::Gen::test2>
  >(\"test2\")", fnGen.bind
    assert_equal ["void Gen_Gen_test2_overload1(int arg0)\n{\n  ::Gen::Gen::test2(std::forward<int>(arg0));\n}",
                  "void Gen_Gen_test2_overload2(int arg0, float arg1)\n{\n  ::Gen::Gen::test2(std::forward<int>(arg0), std::forward<float>(arg1));\n}"], fnGen.extraFunctions


    fnGen.generate(cls, [ fn3 ])
    assert_equal "cobra::function_builder::build<void(*)(bool), &::Gen::Gen::test3>(\"test3\")", fnGen.bind
    assert_equal [], fnGen.extraFunctions


    fnGen.generate(cls, [ fn4 ])
    assert_equal "cobra::function_builder::build_overloaded<
  cobra::function_builder::build_call<int(*)(bool, int), &Gen_Gen_test3_overload2>,
  cobra::function_builder::build_call<int(*)(bool, int, bool), &::Gen::Gen::test3>
  >(\"test3\")", fnGen.bind
    assert_equal ["int Gen_Gen_test3_overload2(bool arg0, int arg1)\n{\n  auto &&result = ::Gen::Gen::test3(std::forward<bool>(arg0), std::forward<int>(arg1));\n  return result;\n}"], fnGen.extraFunctions


    fnGen.generate(cls, [ fn3, fn4 ])
    assert_equal "cobra::function_builder::build_overloaded<
  cobra::function_builder::build_call<void(*)(bool), &::Gen::Gen::test3>,
  cobra::function_builder::build_call<int(*)(bool, int), &Gen_Gen_test3_1_overload2>,
  cobra::function_builder::build_call<int(*)(bool, int, bool), &::Gen::Gen::test3>
  >(\"test3\")", fnGen.bind
    assert_equal ["int Gen_Gen_test3_1_overload2(bool arg0, int arg1)\n{\n  auto &&result = ::Gen::Gen::test3(std::forward<bool>(arg0), std::forward<int>(arg1));\n  return result;\n}"], fnGen.extraFunctions


    fnGen.generate(cls, [ fn5 ])
    assert_equal "cobra::function_builder::build<int(*)(bool, bool), &::Gen::test4>(\"test4\")", fnGen.bind
    assert_equal [], fnGen.extraFunctions


    fnGen.generate(cls, [ fn6 ])
    assert_equal "cobra::function_builder::build_overloaded<
  cobra::function_builder::build_call<int(*)(bool, bool), &Gen_test5_overload2>,
  cobra::function_builder::build_call<int(*)(bool, bool, float), &::Gen::test5>
  >(\"test5\")", fnGen.bind
    assert_equal ["int Gen_test5_overload2(bool arg0, bool arg1)\n{\n  auto &&result = ::Gen::test5(std::forward<bool>(arg0), std::forward<bool>(arg1));\n  return result;\n}"], fnGen.extraFunctions
  end

  def test_functionGenerator
    exposer, lib = exposeLibrary(@gen)

    fnGen = FunctionGenerator.new("")

    assert_equal 2, exposer.exposedMetaData.fullTypes.length

    multiReturnCls = exposer.exposedMetaData.findClass("::Gen::MultipleReturnGen").parsed
    assert_not_nil multiReturnCls
  end
end