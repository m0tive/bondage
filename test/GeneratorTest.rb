require_relative 'TestUtils.rb'

require_relative "../parser/Library.rb"
require_relative "../parser/Parser.rb"
require_relative "../exposer/ParsedLibrary.rb"
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
  end

  def test_functionGenerator
    exposer, lib = exposeLibrary(@gen)

    fnGen = CPP::FunctionGenerator.new("", "")

    assert_equal 7, exposer.exposedMetaData.fullTypes.length

    rootNs = lib.getExposedNamespace()
    assert_not_nil rootNs

    cls = exposer.exposedMetaData.findClass("::Gen::GenCls").parsed
    assert_not_nil cls

    multiReturnCls = exposer.exposedMetaData.findClass("::Gen::MultipleReturnGen").parsed
    assert_not_nil multiReturnCls

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

    fnGen.generate(cls, [ fn1 ], exposer, Set.new())
    assert_equal "bondage::FunctionBuilder::build<
  Gen_GenCls_test1_overload0_t
  >(\"test1\")", fnGen.bind
    assert_equal "Reflect::FunctionCall<Reflect::FunctionSignature< void(::Gen::GenCls::*)(int, float, double) >, &::Gen::GenCls::test1, bondage::FunctionCaller>", fnGen.typedefs["Gen_GenCls_test1_overload0_t"]
    assert_equal [], fnGen.extraFunctions


    fnGen.generate(cls, [ fn2 ], exposer, Set.new())
    assert_equal "Reflect::FunctionArgumentCountSelector<
  GenCls_test2_overload_2,
  GenCls_test2_overload_3,
  GenCls_test2_overload_4
  >", fnGen.typedefs["GenCls_test2_overload"]
    assert_equal "Reflect::FunctionCall<Reflect::FunctionSignature< void(*)(::Gen::GenCls &, int) >, &Gen_GenCls_test2_overload0, bondage::FunctionCaller>", fnGen.typedefs["Gen_GenCls_test2_overload0_t"]
    assert_equal "Reflect::FunctionArgCountSelectorBlock<2,
    Gen_GenCls_test2_overload0_t
    >", fnGen.typedefs["GenCls_test2_overload_2"]
  assert_equal "Reflect::FunctionCall<Reflect::FunctionSignature< void(*)(::Gen::GenCls &, int, float) >, &Gen_GenCls_test2_overload1, bondage::FunctionCaller>", fnGen.typedefs["Gen_GenCls_test2_overload1_t"]
  assert_equal "Reflect::FunctionArgCountSelectorBlock<3,
    Gen_GenCls_test2_overload1_t
    >", fnGen.typedefs["GenCls_test2_overload_3"]
  assert_equal "Reflect::FunctionCall<Reflect::FunctionSignature< void(::Gen::GenCls::*)(int, float, double) >, &::Gen::GenCls::test2, bondage::FunctionCaller>", fnGen.typedefs["Gen_GenCls_test2_overload2_t"]
  assert_equal "Reflect::FunctionArgCountSelectorBlock<4,
    Gen_GenCls_test2_overload2_t
    >", fnGen.typedefs["GenCls_test2_overload_4"]

    assert_equal "bondage::FunctionBuilder::buildOverload< GenCls_test2_overload >(\"test2\")", fnGen.bind
    assert_equal ["void Gen_GenCls_test2_overload0(::Gen::GenCls & inputArg0, int inputArg1)\n{\n  inputArg0.test2(std::forward<int>(inputArg1));\n}",
 "void Gen_GenCls_test2_overload1(::Gen::GenCls & inputArg0, int inputArg1, float inputArg2)\n{\n  inputArg0.test2(std::forward<int>(inputArg1), std::forward<float>(inputArg2));\n}"], fnGen.extraFunctions


    fnGen.generate(cls, [ fn3 ], exposer, Set.new())
    assert_equal "Reflect::FunctionCall<Reflect::FunctionSignature< void(*)(bool) >, &::Gen::GenCls::test3, Reflect::MethodInjectorBuilder<bondage::FunctionCaller>>", fnGen.typedefs["Gen_GenCls_test3_overload0_t"]
    assert_equal "bondage::FunctionBuilder::build<
  Gen_GenCls_test3_overload0_t
  >(\"test3\")", fnGen.bind
    assert_equal [], fnGen.extraFunctions


    fnGen.generate(cls, [ fn4 ], exposer, Set.new())
    assert_equal "Reflect::FunctionCall<Reflect::FunctionSignature< int(*)(bool, int) >, &Gen_GenCls_test3_overload0, Reflect::MethodInjectorBuilder<bondage::FunctionCaller>>", fnGen.typedefs["Gen_GenCls_test3_overload0_t"]
    assert_equal "Reflect::FunctionArgCountSelectorBlock<2,
    Gen_GenCls_test3_overload0_t
    >", fnGen.typedefs["GenCls_test3_overload_2"]
    assert_equal "Reflect::FunctionCall<Reflect::FunctionSignature< int(*)(bool, int, bool) >, &::Gen::GenCls::test3, Reflect::MethodInjectorBuilder<bondage::FunctionCaller>>", fnGen.typedefs["Gen_GenCls_test3_overload1_t"]
    assert_equal "Reflect::FunctionArgCountSelectorBlock<3,
    Gen_GenCls_test3_overload1_t
    >", fnGen.typedefs["GenCls_test3_overload_3"]
    assert_equal "Reflect::FunctionArgumentCountSelector<
  GenCls_test3_overload_2,
  GenCls_test3_overload_3
  >", fnGen.typedefs["GenCls_test3_overload"]
    assert_equal "bondage::FunctionBuilder::buildOverload< GenCls_test3_overload >(\"test3\")", fnGen.bind
    assert_equal ["int Gen_GenCls_test3_overload0(bool inputArg0, int inputArg1)\n{\n  auto result = ::Gen::GenCls::test3(std::forward<bool>(inputArg0), std::forward<int>(inputArg1));\n  return result;\n}"], fnGen.extraFunctions


    fnGen.generate(cls, [ fn3, fn4 ], exposer, Set.new())
    assert_equal "Reflect::FunctionCall<Reflect::FunctionSignature< void(*)(bool) >, &::Gen::GenCls::test3, Reflect::MethodInjectorBuilder<bondage::FunctionCaller>>", fnGen.typedefs["Gen_GenCls_test3_overload0_t"]
    assert_equal "Reflect::FunctionArgCountSelectorBlock<1,
    Gen_GenCls_test3_overload0_t
    >", fnGen.typedefs["GenCls_test3_overload_1"]
    assert_equal "Reflect::FunctionCall<Reflect::FunctionSignature< int(*)(bool, int) >, &Gen_GenCls_test3_overload1, Reflect::MethodInjectorBuilder<bondage::FunctionCaller>>", fnGen.typedefs["Gen_GenCls_test3_overload1_t"]
    assert_equal "Reflect::FunctionArgCountSelectorBlock<2,
    Gen_GenCls_test3_overload1_t
    >", fnGen.typedefs["GenCls_test3_overload_2"]
    assert_equal "Reflect::FunctionCall<Reflect::FunctionSignature< int(*)(bool, int, bool) >, &::Gen::GenCls::test3, Reflect::MethodInjectorBuilder<bondage::FunctionCaller>>", fnGen.typedefs["Gen_GenCls_test3_overload2_t"]
    assert_equal "Reflect::FunctionArgCountSelectorBlock<3,
    Gen_GenCls_test3_overload2_t
    >", fnGen.typedefs["GenCls_test3_overload_3"]
    assert_equal "Reflect::FunctionArgumentCountSelector<
  GenCls_test3_overload_1,
  GenCls_test3_overload_2,
  GenCls_test3_overload_3
  >", fnGen.typedefs["GenCls_test3_overload"]
    assert_equal "bondage::FunctionBuilder::buildOverload< GenCls_test3_overload >(\"test3\")", fnGen.bind
    assert_equal ["int Gen_GenCls_test3_overload1(bool inputArg0, int inputArg1)\n{\n  auto result = ::Gen::GenCls::test3(std::forward<bool>(inputArg0), std::forward<int>(inputArg1));\n  return result;\n}"], fnGen.extraFunctions


    fnGen.generate(cls, [ fn5 ], exposer, Set.new())
    assert_equal "Reflect::FunctionCall<Reflect::FunctionSignature< int(*)(bool, bool) >, &::Gen::test4, Reflect::MethodInjectorBuilder<bondage::FunctionCaller>>", fnGen.typedefs["Gen_test4_overload0_t"]
    assert_equal "bondage::FunctionBuilder::build<
  Gen_test4_overload0_t
  >(\"test4\")", fnGen.bind
    assert_equal [], fnGen.extraFunctions


    fnGen.generate(cls, [ fn6 ], exposer, Set.new())
    assert_equal "Reflect::FunctionArgumentCountSelector<
  GenCls_test5_overload_2,
  GenCls_test5_overload_3
  >", fnGen.typedefs["GenCls_test5_overload"]
    assert_equal "Reflect::FunctionArgCountSelectorBlock<2,
    Gen_test5_overload0_t
    >", fnGen.typedefs["GenCls_test5_overload_2"]
    assert_equal "Reflect::FunctionArgCountSelectorBlock<3,
    Gen_test5_overload1_t
    >", fnGen.typedefs["GenCls_test5_overload_3"]
    assert_equal "Reflect::FunctionCall<Reflect::FunctionSignature< int(*)(bool, bool) >, &Gen_test5_overload0, Reflect::MethodInjectorBuilder<bondage::FunctionCaller>>", fnGen.typedefs["Gen_test5_overload0_t"]
    assert_equal "Reflect::FunctionCall<Reflect::FunctionSignature< int(*)(bool, bool, float) >, &::Gen::test5, Reflect::MethodInjectorBuilder<bondage::FunctionCaller>>", fnGen.typedefs["Gen_test5_overload1_t"]
    assert_equal "bondage::FunctionBuilder::buildOverload< GenCls_test5_overload >(\"test5\")", fnGen.bind
    assert_equal ["int Gen_test5_overload0(bool inputArg0, bool inputArg1)\n{\n  auto result = ::Gen::test5(std::forward<bool>(inputArg0), std::forward<bool>(inputArg1));\n  return result;\n}"], fnGen.extraFunctions
  end

  def test_functionGeneratorParamDirection
    exposer, lib = exposeLibrary(@gen)

    fnGen = CPP::FunctionGenerator.new("", "")

    assert_equal 7, exposer.exposedMetaData.fullTypes.length

    multiReturnCls = exposer.exposedMetaData.findClass("::Gen::MultipleReturnGen").parsed
    assert_not_nil multiReturnCls

    fn1 = multiReturnCls.functions[0]
    assert_not_nil(fn1)
    assert_equal "test", fn1.name

    fn2 = multiReturnCls.functions[1]
    assert_not_nil(fn2)
    assert_equal "test", fn2.name

    fnGen.generate(multiReturnCls, [ fn1, fn2 ], exposer, Set.new())

    assert_equal "Reflect::FunctionCall<Reflect::FunctionSignature< int(*)(::Gen::MultipleReturnGen &) >, &Gen_MultipleReturnGen_test_overload0, bondage::FunctionCaller>", fnGen.typedefs["Gen_MultipleReturnGen_test_overload0_t"]
    assert_equal "Reflect::FunctionArgCountSelectorBlock<2,
    Gen_MultipleReturnGen_test_overload0_t
    >", fnGen.typedefs["MultipleReturnGen_test_overload_2"]
    assert_equal "Reflect::FunctionCall<Reflect::FunctionSignature< int(*)(::Gen::MultipleReturnGen &, Gen::MultipleReturnGen *) >, &Gen_MultipleReturnGen_test_overload1, bondage::FunctionCaller>", fnGen.typedefs["Gen_MultipleReturnGen_test_overload1_t"]
    assert_equal "Reflect::FunctionArgCountSelectorBlock<3,
    Gen_MultipleReturnGen_test_overload1_t
    >", fnGen.typedefs["MultipleReturnGen_test_overload_3"]
    assert_equal "Reflect::FunctionCall<Reflect::FunctionSignature< std::tuple< double, Gen::MultipleReturnGen, const int >(*)(::Gen::MultipleReturnGen &, const int &, Gen::MultipleReturnGen &) >, &Gen_MultipleReturnGen_test_overload2, bondage::FunctionCaller>", fnGen.typedefs["Gen_MultipleReturnGen_test_overload2_t"]
    assert_equal "Reflect::FunctionArgCountSelectorBlock<4,
    Gen_MultipleReturnGen_test_overload2_t
    >", fnGen.typedefs["MultipleReturnGen_test_overload_4"]
    assert_equal "Reflect::FunctionArgumentCountSelector<
  MultipleReturnGen_test_overload_2,
  MultipleReturnGen_test_overload_3,
  MultipleReturnGen_test_overload_4
  >", fnGen.typedefs["MultipleReturnGen_test_overload"]

    assert_equal "bondage::FunctionBuilder::buildOverload< MultipleReturnGen_test_overload >(\"test\")", fnGen.bind

    assert_equal ["int Gen_MultipleReturnGen_test_overload0(::Gen::MultipleReturnGen & inputArg0)
{
  int result;

  inputArg0.test(&result);
  return result;
}",
"int Gen_MultipleReturnGen_test_overload1(::Gen::MultipleReturnGen & inputArg0, Gen::MultipleReturnGen * inputArg1)
{
  int result;

  inputArg0.test(&result, std::forward<Gen::MultipleReturnGen *>(inputArg1));
  return result;
}",
"std::tuple< double, Gen::MultipleReturnGen, const int > Gen_MultipleReturnGen_test_overload2(::Gen::MultipleReturnGen & inputArg0, const int & inputArg1, Gen::MultipleReturnGen & inputArg2)
{
  std::tuple< double, Gen::MultipleReturnGen, const int > result;
  std::get<1>(result) =  std::forward<Gen::MultipleReturnGen &>(inputArg2);

  std::get<0>(result) = inputArg0.test(std::forward<const int &>(inputArg1), std::get<1>(result), std::get<2>(result));
  return result;
}"],
      fnGen.extraFunctions
  end

  def test_functionGeneratorConstructors
    exposer, lib = exposeLibrary(@gen)

    fnGen = CPP::FunctionGenerator.new("", "")

    assert_equal 7, exposer.exposedMetaData.fullTypes.length

    rootNs = lib.getExposedNamespace()
    assert_not_nil rootNs

    cls = exposer.exposedMetaData.findClass("::Gen::CtorGen").parsed
    assert_not_nil cls

    fns = exposer.findExposedFunctions(cls)
    assert_equal 1, fns.length

    ctors = fns["CtorGen"]
    assert_not_nil ctors

    assert_equal 2, ctors.length

    fnGen = CPP::FunctionGenerator.new("", "")

    fnGen.generate(cls, ctors, exposer, Set.new())

    assert_equal "Reflect::FunctionCall<Reflect::FunctionSignature< ::Gen::CtorGen *(*)() >, &Gen_CtorGen_CtorGen_overload0, Reflect::MethodInjectorBuilder<bondage::FunctionCaller>>", fnGen.typedefs["Gen_CtorGen_CtorGen_overload0_t"]
    assert_equal "Reflect::FunctionArgCountSelectorBlock<1,
    Gen_CtorGen_CtorGen_overload0_t
    >", fnGen.typedefs["CtorGen_CtorGen_overload_1"]
    assert_equal "Reflect::FunctionCall<Reflect::FunctionSignature< std::tuple< ::Gen::CtorGen *, int >(*)() >, &Gen_CtorGen_CtorGen_overload1, Reflect::MethodInjectorBuilder<bondage::FunctionCaller>>", fnGen.typedefs["Gen_CtorGen_CtorGen_overload1_t"]
    assert_equal "Reflect::FunctionArgCountSelectorBlock<2,
    Gen_CtorGen_CtorGen_overload1_t
    >", fnGen.typedefs["CtorGen_CtorGen_overload_2"]
    assert_equal "Reflect::FunctionArgumentCountSelector<
  CtorGen_CtorGen_overload_1,
  CtorGen_CtorGen_overload_2
  >", fnGen.typedefs["CtorGen_CtorGen_overload"]
    assert_equal "bondage::FunctionBuilder::buildOverload< CtorGen_CtorGen_overload >(\"CtorGen\")", fnGen.bind
    assert_equal ["::Gen::CtorGen * Gen_CtorGen_CtorGen_overload0()\n{\n  auto result = bondage::WrappedClassHelper< ::Gen::CtorGen >::create();\n  return result;\n}",
 "std::tuple< ::Gen::CtorGen *, int > Gen_CtorGen_CtorGen_overload1()\n{\n  std::tuple< ::Gen::CtorGen *, int > result;\n\n  std::get<0>(result) = bondage::WrappedClassHelper< ::Gen::CtorGen >::create(&std::get<1>(result));\n  return result;\n}"], fnGen.extraFunctions
  end

  def test_classGenerator
    exposer, lib = exposeLibrary(@gen)

    gen = CPP::ClassGenerator.new()

    cls = exposer.exposedMetaData.findClass("::Gen::GenCls")
    assert_not_nil cls

    gen.generate(exposer, cls, "var", Set.new())
    assert_equal "BONDAGE_EXPOSED_CLASS_DERIVABLE_MANAGED(GEN_EXPORT, ::Gen::GenCls)", gen.interface

    derived = exposer.exposedMetaData.findClass("::Gen::InheritTest");
    cls = derived.parsed
    assert_not_nil derived.parentClass
    assert_not_nil cls

    gen.generate(exposer, derived, "var", Set.new())
    assert_equal "BONDAGE_EXPOSED_DERIVED_CLASS(GEN_EXPORT, ::Gen::InheritTest, ::Gen::GenCls, ::Gen::GenCls)", gen.interface

    libGen = CPP::LibraryGenerator.new(HeaderHelper.new)

    expectedHeader = lib.library.autogenPath(:cpp) + "/../autogen_baked/Gen.h"
    expectedSource = lib.library.autogenPath(:cpp) + "/../autogen_baked/Gen.cpp"

    libGen.generate(lib, exposer)

    if (true)
      FileUtils.mkdir_p(lib.library.autogenPath(:cpp))
      File.open(expectedHeader, 'w') do |file|  
        file.write(libGen.header)
      end
      File.open(expectedSource, 'w') do |file|
        file.write(libGen.source)
      end
    end

    assert_equal File.read(expectedHeader), libGen.header
    assert_equal File.read(expectedSource), libGen.source
    cleanLibrary(@gen)
  end

  def test_stringLibGenerator
    stringLibrary = Library.new("String", "test/testData/StringLibrary")
    stringLibrary.addIncludePath(".")
    stringLibrary.addFile("StringLibrary.h")
    setupLibrary(stringLibrary)

    genExposer, genLib = exposeLibrary(@gen)
    exposer, lib = exposeLibrary(stringLibrary)

    libGen = CPP::LibraryGenerator.new(HeaderHelper.new)

    expectedHeader = libGen.headerPath(genLib.library)
    expectedSource = libGen.sourcePath(genLib.library)

    libGen.generate(genLib, genExposer)

    FileUtils.mkdir_p(genLib.library.autogenPath(:cpp))
    File.open(expectedHeader, 'w') do |file|
      file.write(libGen.header)
    end
    File.open(expectedSource, 'w') do |file|
      file.write(libGen.source)
    end

    libGen.generate(lib, exposer)

    expectedHeader = libGen.headerPath(lib.library)
    expectedSource = libGen.sourcePath(lib.library)

    FileUtils.mkdir_p(lib.library.autogenPath(:cpp))
    File.open(expectedHeader, 'w') do |file|
      file.write(libGen.header)
    end
    File.open(expectedSource, 'w') do |file|
      file.write(libGen.source)
    end

    if (os != :windows)
      runProcess("test/testGenerator.sh")
    else
      #runProcess("test/testGenerator.bat")
    end

    cleanLibrary(stringLibrary)
    cleanLibrary(@gen)
  end
end