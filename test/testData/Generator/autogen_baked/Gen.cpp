// Copyright me, fool. No, copying and stuff.
//
// This file is auto generated, do not change it!
//
#include "autogen_Gen/Gen.h"
#include "bondage/RuntimeHelpersImpl.h"
#include "utility"
#include "tuple"
#include "Generator.h"


using namespace Gen;


int Gen_test5_overload0(bool inputArg0, bool inputArg1)
{
  auto result = ::Gen::test5(std::forward<bool>(inputArg0), std::forward<bool>(inputArg1));
  return result;
}

const bondage::Function g_bondage_library_Gen_methods[] = {
  bondage::FunctionBuilder::build<
    bondage::FunctionBuilder::buildCall< int(*)(bool, bool), &::Gen::test4 >
    >("test4"),
  bondage::FunctionBuilder::buildOverload< Reflect::FunctionArgumentCountSelector<
    Reflect::FunctionArgCountSelectorBlock<2,
      bondage::FunctionBuilder::buildCall< int(*)(bool, bool), &Gen_test5_overload0 >
      >,
    Reflect::FunctionArgCountSelectorBlock<3,
      bondage::FunctionBuilder::buildCall< int(*)(bool, bool, float), &::Gen::test5 >
      >
    > >("test5")
};


bondage::Library g_bondage_library_Gen(
  "Gen",
  g_bondage_library_Gen_methods,
  2);
namespace Gen
{
const bondage::Library &bindings()
{
  return g_bondage_library_Gen;
}
}


// Exposing class ::Gen::CtorGen
::Gen::CtorGen * Gen_CtorGen_CtorGen_overload0()
{
  auto result = bondage::WrappedClassHelper< ::Gen::CtorGen >::create();
  return result;
}

std::tuple< ::Gen::CtorGen *, int > Gen_CtorGen_CtorGen_overload1()
{
  std::tuple< ::Gen::CtorGen *, int > result;

  std::get<0>(result) = bondage::WrappedClassHelper< ::Gen::CtorGen >::create(&std::get<1>(result));
  return result;
}

const bondage::Function Gen_CtorGen_methods[] = {
  bondage::FunctionBuilder::buildOverload< Reflect::FunctionArgumentCountSelector<
    Reflect::FunctionArgCountSelectorBlock<1,
      bondage::FunctionBuilder::buildCall< ::Gen::CtorGen *(*)(), &Gen_CtorGen_CtorGen_overload0 >
      >,
    Reflect::FunctionArgCountSelectorBlock<2,
      bondage::FunctionBuilder::buildCall< std::tuple< ::Gen::CtorGen *, int >(*)(), &Gen_CtorGen_CtorGen_overload1 >
      >
    > >("CtorGen")
};


BONDAGE_IMPLEMENT_EXPOSED_CLASS(
  Gen_CtorGen,
  g_bondage_library_Gen,
  ::Gen,
  CtorGen,
  Gen_CtorGen_methods,
  1);



// Exposing class ::Gen::MultipleReturnGen
int Gen_MultipleReturnGen_test_overload0(::Gen::MultipleReturnGen & inputArg0)
{
  int result;

  inputArg0.test(&result);
  return result;
}

int Gen_MultipleReturnGen_test_overload1(::Gen::MultipleReturnGen & inputArg0, Gen::MultipleReturnGen * inputArg1)
{
  int result;

  inputArg0.test(&result, std::forward<Gen::MultipleReturnGen *>(inputArg1));
  return result;
}

std::tuple< double, Gen::MultipleReturnGen, const int > Gen_MultipleReturnGen_test_overload2(::Gen::MultipleReturnGen & inputArg0, const int & inputArg1, Gen::MultipleReturnGen & inputArg2)
{
  std::tuple< double, Gen::MultipleReturnGen, const int > result;
  std::get<1>(result) =  std::forward<Gen::MultipleReturnGen &>(inputArg2);

  std::get<0>(result) = inputArg0.test(std::forward<const int &>(inputArg1), std::get<1>(result), std::get<2>(result));
  return result;
}

const bondage::Function Gen_MultipleReturnGen_methods[] = {
  bondage::FunctionBuilder::buildOverload< Reflect::FunctionArgumentCountSelector<
    Reflect::FunctionArgCountSelectorBlock<2,
      bondage::FunctionBuilder::buildMemberStandinCall< int(*)(::Gen::MultipleReturnGen &), &Gen_MultipleReturnGen_test_overload0 >
      >,
    Reflect::FunctionArgCountSelectorBlock<3,
      bondage::FunctionBuilder::buildMemberStandinCall< int(*)(::Gen::MultipleReturnGen &, Gen::MultipleReturnGen *), &Gen_MultipleReturnGen_test_overload1 >
      >,
    Reflect::FunctionArgCountSelectorBlock<4,
      bondage::FunctionBuilder::buildMemberStandinCall< std::tuple< double, Gen::MultipleReturnGen, const int >(*)(::Gen::MultipleReturnGen &, const int &, Gen::MultipleReturnGen &), &Gen_MultipleReturnGen_test_overload2 >
      >
    > >("test")
};


BONDAGE_IMPLEMENT_EXPOSED_CLASS(
  Gen_MultipleReturnGen,
  g_bondage_library_Gen,
  ::Gen,
  MultipleReturnGen,
  Gen_MultipleReturnGen_methods,
  1);



// Exposing class ::Gen::GenCls
void Gen_GenCls_test2_overload0(::Gen::GenCls & inputArg0, int inputArg1)
{
  inputArg0.test2(std::forward<int>(inputArg1));
}

void Gen_GenCls_test2_overload1(::Gen::GenCls & inputArg0, int inputArg1, float inputArg2)
{
  inputArg0.test2(std::forward<int>(inputArg1), std::forward<float>(inputArg2));
}

int Gen_GenCls_test3_overload1(bool inputArg0, int inputArg1)
{
  auto result = ::Gen::GenCls::test3(std::forward<bool>(inputArg0), std::forward<int>(inputArg1));
  return result;
}

const bondage::Function Gen_GenCls_methods[] = {
  bondage::FunctionBuilder::build<
    bondage::FunctionBuilder::buildCall< void(::Gen::GenCls::*)(int, float, double), &::Gen::GenCls::test1 >
    >("test1"),
  bondage::FunctionBuilder::buildOverload< Reflect::FunctionArgumentCountSelector<
    Reflect::FunctionArgCountSelectorBlock<2,
      bondage::FunctionBuilder::buildMemberStandinCall< void(*)(::Gen::GenCls &, int), &Gen_GenCls_test2_overload0 >
      >,
    Reflect::FunctionArgCountSelectorBlock<3,
      bondage::FunctionBuilder::buildMemberStandinCall< void(*)(::Gen::GenCls &, int, float), &Gen_GenCls_test2_overload1 >
      >,
    Reflect::FunctionArgCountSelectorBlock<4,
      bondage::FunctionBuilder::buildCall< void(::Gen::GenCls::*)(int, float, double), &::Gen::GenCls::test2 >
      >
    > >("test2"),
  bondage::FunctionBuilder::buildOverload< Reflect::FunctionArgumentCountSelector<
    Reflect::FunctionArgCountSelectorBlock<1,
      bondage::FunctionBuilder::buildCall< void(*)(bool), &::Gen::GenCls::test3 >
      >,
    Reflect::FunctionArgCountSelectorBlock<2, Reflect::FunctionArgumentTypeSelector<
      bondage::FunctionBuilder::buildCall< int(*)(bool, int), &Gen_GenCls_test3_overload1 >,
      bondage::FunctionBuilder::buildCall< int(*)(float, float), &::Gen::GenCls::test3 >
      > >,
    Reflect::FunctionArgCountSelectorBlock<3,
      bondage::FunctionBuilder::buildCall< int(*)(bool, int, bool), &::Gen::GenCls::test3 >
      >
    > >("test3")
};


BONDAGE_IMPLEMENT_EXPOSED_CLASS(
  Gen_GenCls,
  g_bondage_library_Gen,
  ::Gen,
  GenCls,
  Gen_GenCls_methods,
  3);



// Exposing class ::Gen::InheritTest
const bondage::Function Gen_InheritTest_methods[] = {
  bondage::FunctionBuilder::build<
    bondage::FunctionBuilder::buildCall< void(::Gen::InheritTest::*)(), &::Gen::InheritTest::pork >
    >("pork"),
  bondage::FunctionBuilder::build<
    bondage::FunctionBuilder::buildCall< int(::Gen::InheritTest::*)(), &::Gen::InheritTest::pork2 >
    >("pork2")
};


BONDAGE_IMPLEMENT_EXPOSED_CLASS(
  Gen_InheritTest,
  g_bondage_library_Gen,
  ::Gen,
  InheritTest,
  Gen_InheritTest_methods,
  2);



// Exposing class ::Gen::InheritTest2
BONDAGE_IMPLEMENT_EXPOSED_CLASS(
  Gen_InheritTest2,
  g_bondage_library_Gen,
  ::Gen,
  InheritTest2,
  nullptr,
  0);


#include "CastHelper.Gen_GenCls.h"

const bondage::WrappedClass *Gen_Gen_GenCls_caster(const void *vPtr)
{
  auto ptr = static_cast<const ::Gen::GenCls*>(vPtr);

  if (Crate::CastHelper< ::Gen::GenCls, ::Gen::InheritTest2 >::canCast(ptr))
  {
    return &Gen_InheritTest2;
  }
  if (Crate::CastHelper< ::Gen::GenCls, ::Gen::InheritTest >::canCast(ptr))
  {
    return &Gen_InheritTest;
  }
  return nullptr;
}

bondage::CastHelperLibrary g_Gen_Gen_GenCls_caster(bondage::WrappedClassFinder< ::Gen::GenCls >::castHelper(), Gen_Gen_GenCls_caster);


