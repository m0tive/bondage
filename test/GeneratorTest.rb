require_relative 'TestUtils.rb'

require_relative "../parser/Library.rb"
require_relative "../parser/Parser.rb"
require_relative "../exposer/ExposeAst.rb"
require_relative "../generators/CPP/LibraryGenerator.rb"

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

    fnGen = CPP::FunctionGenerator.new("")

    assert_equal 4, exposer.exposedMetaData.fullTypes.length

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

    fnGen.generate(cls, [ fn1 ])
    assert_equal "cobra::function_builder::build<
  cobra::function_builder::build_call<void(::Gen::Gen::*)(int, float, double), &::Gen::Gen::test1>
  >(\"test1\")", fnGen.bind
    assert_equal [], fnGen.extraFunctions


    fnGen.generate(cls, [ fn2 ])
    assert_equal "cobra::function_builder::build_overloaded<
  cobra::function_builder::build_member_standin_call<void(*)(::Gen::Gen &, int), &Gen_Gen_test2_overload0>,
  cobra::function_builder::build_member_standin_call<void(*)(::Gen::Gen &, int, float), &Gen_Gen_test2_overload1>,
  cobra::function_builder::build_call<void(::Gen::Gen::*)(int, float, double), &::Gen::Gen::test2>
  >(\"test2\")", fnGen.bind
    assert_equal ["void Gen_Gen_test2_overload0(::Gen::Gen & inputArg0, int inputArg1)\n{\n  inputArg0.test2(std::forward<int>(inputArg1));\n}",
 "void Gen_Gen_test2_overload1(::Gen::Gen & inputArg0, int inputArg1, float inputArg2)\n{\n  inputArg0.test2(std::forward<int>(inputArg1), std::forward<float>(inputArg2));\n}"], fnGen.extraFunctions


    fnGen.generate(cls, [ fn3 ])
    assert_equal "cobra::function_builder::build<
  cobra::function_builder::build_call<void(*)(bool), &::Gen::Gen::test3>
  >(\"test3\")", fnGen.bind
    assert_equal [], fnGen.extraFunctions


    fnGen.generate(cls, [ fn4 ])
    assert_equal "cobra::function_builder::build_overloaded<
  cobra::function_builder::build_call<int(*)(bool, int), &Gen_Gen_test3_overload0>,
  cobra::function_builder::build_call<int(*)(bool, int, bool), &::Gen::Gen::test3>
  >(\"test3\")", fnGen.bind
    assert_equal ["int Gen_Gen_test3_overload0(bool inputArg0, int inputArg1)\n{\n  auto &&result = ::Gen::Gen::test3(std::forward<bool>(inputArg0), std::forward<int>(inputArg1));\n  return result;\n}"], fnGen.extraFunctions


    fnGen.generate(cls, [ fn3, fn4 ])
    assert_equal "cobra::function_builder::build_overloaded<
  cobra::function_builder::build_call<void(*)(bool), &::Gen::Gen::test3>,
  cobra::function_builder::build_call<int(*)(bool, int), &Gen_Gen_test3_overload1>,
  cobra::function_builder::build_call<int(*)(bool, int, bool), &::Gen::Gen::test3>
  >(\"test3\")", fnGen.bind
    assert_equal ["int Gen_Gen_test3_overload1(bool inputArg0, int inputArg1)\n{\n  auto &&result = ::Gen::Gen::test3(std::forward<bool>(inputArg0), std::forward<int>(inputArg1));\n  return result;\n}"], fnGen.extraFunctions


    fnGen.generate(cls, [ fn5 ])
    assert_equal "cobra::function_builder::build<
  cobra::function_builder::build_call<int(*)(bool, bool), &::Gen::test4>
  >(\"test4\")", fnGen.bind
    assert_equal [], fnGen.extraFunctions


    fnGen.generate(cls, [ fn6 ])
    assert_equal "cobra::function_builder::build_overloaded<
  cobra::function_builder::build_call<int(*)(bool, bool), &Gen_test5_overload0>,
  cobra::function_builder::build_call<int(*)(bool, bool, float), &::Gen::test5>
  >(\"test5\")", fnGen.bind
    assert_equal ["int Gen_test5_overload0(bool inputArg0, bool inputArg1)\n{\n  auto &&result = ::Gen::test5(std::forward<bool>(inputArg0), std::forward<bool>(inputArg1));\n  return result;\n}"], fnGen.extraFunctions
  end

  def test_functionGeneratorParamDirection
    exposer, lib = exposeLibrary(@gen)

    fnGen = CPP::FunctionGenerator.new("")

    assert_equal 4, exposer.exposedMetaData.fullTypes.length

    multiReturnCls = exposer.exposedMetaData.findClass("::Gen::MultipleReturnGen").parsed
    assert_not_nil multiReturnCls

    fn1 = multiReturnCls.functions[0]
    assert_not_nil(fn1)
    assert_equal "test", fn1.name

    fn2 = multiReturnCls.functions[1]
    assert_not_nil(fn2)
    assert_equal "test", fn2.name

    fnGen.generate(multiReturnCls, [ fn1, fn2 ])
    assert_equal "cobra::function_builder::build_overloaded<
  cobra::function_builder::build_member_standin_call<int(*)(::Gen::MultipleReturnGen &), &Gen_MultipleReturnGen_test_overload0>,
  cobra::function_builder::build_member_standin_call<std::tuple<int, float>(*)(::Gen::MultipleReturnGen &, float *), &Gen_MultipleReturnGen_test_overload1>,
  cobra::function_builder::build_member_standin_call<std::tuple<double, int, int>(*)(::Gen::MultipleReturnGen &, int &, int *), &Gen_MultipleReturnGen_test_overload2>
  >(\"test\")", fnGen.bind
    assert_equal [
      "int Gen_MultipleReturnGen_test_overload0(::Gen::MultipleReturnGen & inputArg0)\n{\n  int result;\n\ninputArg0.test(&result);\n  return result;\n}",
      "std::tuple<int, float> Gen_MultipleReturnGen_test_overload1(::Gen::MultipleReturnGen & inputArg0, float * inputArg1)\n{\n  std::tuple<int, float> result;\nstd::tuple::get<1>(result) = * std::forward<float *>(inputArg1);\n\ninputArg0.test(&std::tuple::get<0>(result), &std::tuple::get<1>(result));\n  return result;\n}",
      "std::tuple<double, int, int> Gen_MultipleReturnGen_test_overload2(::Gen::MultipleReturnGen & inputArg0, int & inputArg1, int * inputArg2)\n{\n  std::tuple<double, int, int> result;\nstd::tuple::get<1>(result) = * std::forward<int *>(inputArg2);\n\nstd::tuple::get<0>(result) = inputArg0.test(std::forward<int &>(inputArg1), &std::tuple::get<1>(result), std::tuple::get<2>(result));\n  return result;\n}"], 
      fnGen.extraFunctions
  end

  def test_functionGeneratorConstructors
    exposer, lib = exposeLibrary(@gen)

    fnGen = CPP::FunctionGenerator.new("")

    assert_equal 4, exposer.exposedMetaData.fullTypes.length

    rootNs = lib.getExposedNamespace()
    assert_not_nil rootNs

    cls = exposer.exposedMetaData.findClass("::Gen::CtorGen").parsed
    assert_not_nil cls

    fns = exposer.findExposedFunctions(cls)
    assert_equal 1, fns.length

    ctors = fns["CtorGen"]
    assert_not_nil ctors

    assert_equal 2, ctors.length

    fnGen = CPP::FunctionGenerator.new("")

    fnGen.generate(cls, ctors)

    assert_equal "cobra::function_builder::build_overloaded<
  cobra::function_builder::build_call<::Gen::CtorGen *(*)(), &Gen_CtorGen_CtorGen_overload0>,
  cobra::function_builder::build_call<std::tuple<::Gen::CtorGen *, int>(*)(), &Gen_CtorGen_CtorGen_overload1>
  >(\"CtorGen\")", fnGen.bind
    assert_equal [
      "::Gen::CtorGen * Gen_CtorGen_CtorGen_overload0()\n{\n  auto &&result = Cobra::Type<::Gen::CtorGen>::create()\n  return result;\n}",
      "std::tuple<::Gen::CtorGen *, int> Gen_CtorGen_CtorGen_overload1()\n{\n  std::tuple<::Gen::CtorGen *, int> result;\n\nstd::tuple::get<0>(result) = Cobra::Type<::Gen::CtorGen>::create(&std::tuple::get<1>(result))\n  return result;\n}"], fnGen.extraFunctions
  end

  def test_classGenerator
    exposer, lib = exposeLibrary(@gen)

    gen = CPP::ClassGenerator.new()

    cls = exposer.exposedMetaData.findClass("::Gen::Gen").parsed
    assert_not_nil cls

    gen.generate(exposer, cls)
    assert_equal "COBRA_EXPOSED_CLASS_MANAGED(::Gen::Gen)", gen.interface

    derived = exposer.exposedMetaData.findClass("::Gen::InheritTest");
    cls = derived.parsed
    assert_not_nil derived.parentClass
    assert_not_nil cls

    gen.generate(exposer, cls)
    assert_equal "COBRA_EXPOSED_DERIVED_CLASS(::Gen::InheritTest, ::Gen::Gen, ::Gen::Gen)", gen.interface


  end
end