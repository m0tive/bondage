// Copyright me, fool. No, copying and stuff.
//
// This file is auto generated, do not change it!
//
#include "autogen_Gen/Gen.h"
#include "bondage/RuntimeHelpersImpl.h"
#include "utility"
#include "tuple"


bondage::Library g_bondage_library;
namespace Gen
{
const bondage::Library &bindings()
{
  return g_bondage_library;
}
}


// Exposing class ::Gen::Gen

void Gen_Gen_test2_overload0(::Gen::Gen & inputArg0, int inputArg1)
{
  inputArg0.test2(std::forward<int>(inputArg1));
}

void Gen_Gen_test2_overload1(::Gen::Gen & inputArg0, int inputArg1, float inputArg2)
{
  inputArg0.test2(std::forward<int>(inputArg1), std::forward<float>(inputArg2));
}

int Gen_Gen_test3_overload1(bool inputArg0, int inputArg1)
{
  auto result = ::Gen::Gen::test3(std::forward<bool>(inputArg0), std::forward<int>(inputArg1));
  return result;
}

const bondage::Function Gen_Gen_methods[] = {
  bondage::FunctionBuilder::build<
    bondage::FunctionBuilder::buildCall< void(::Gen::Gen::*)(int, float, double), &::Gen::Gen::test1 >
    >("test1"),
  bondage::FunctionBuilder::buildOverloaded<
    bondage::FunctionBuilder::buildMemberStandinCall< void(*)(::Gen::Gen &, int), &Gen_Gen_test2_overload0 >,
    bondage::FunctionBuilder::buildMemberStandinCall< void(*)(::Gen::Gen &, int, float), &Gen_Gen_test2_overload1 >,
    bondage::FunctionBuilder::buildCall< void(::Gen::Gen::*)(int, float, double), &::Gen::Gen::test2 >
    >("test2"),
  bondage::FunctionBuilder::buildOverloaded<
    bondage::FunctionBuilder::buildCall< void(*)(bool), &::Gen::Gen::test3 >,
    bondage::FunctionBuilder::buildCall< int(*)(bool, int), &Gen_Gen_test3_overload1 >,
    bondage::FunctionBuilder::buildCall< int(*)(bool, int, bool), &::Gen::Gen::test3 >
    >("test3")
};

BONDAGE_IMPLEMENT_EXPOSED_CLASS(
  g_bondage_library,
  ::Gen::Gen,
  Gen_Gen_methods);



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
  g_bondage_library,
  ::Gen::InheritTest,
  Gen_InheritTest_methods);



// Exposing class ::Gen::MultipleReturnGen

int Gen_MultipleReturnGen_test_overload0(::Gen::MultipleReturnGen & inputArg0)
{
  int result;

  inputArg0.test(&result);
  return result;
}

std::tuple< int, float > Gen_MultipleReturnGen_test_overload1(::Gen::MultipleReturnGen & inputArg0, float * inputArg1)
{
  std::tuple< int, float > result;
  std::get<1>(result) = * std::forward<float *>(inputArg1);

  inputArg0.test(&std::get<0>(result), &std::get<1>(result));
  return result;
}

const bondage::Function Gen_MultipleReturnGen_methods[] = {
  bondage::FunctionBuilder::buildOverloaded<
    bondage::FunctionBuilder::buildMemberStandinCall< int(*)(::Gen::MultipleReturnGen &), &Gen_MultipleReturnGen_test_overload0 >,
    bondage::FunctionBuilder::buildMemberStandinCall< std::tuple< int, float >(*)(::Gen::MultipleReturnGen &, float *), &Gen_MultipleReturnGen_test_overload1 >
    >("test")
};

BONDAGE_IMPLEMENT_EXPOSED_CLASS(
  g_bondage_library,
  ::Gen::MultipleReturnGen,
  Gen_MultipleReturnGen_methods);



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
  bondage::FunctionBuilder::buildOverloaded<
    bondage::FunctionBuilder::buildCall< ::Gen::CtorGen *(*)(), &Gen_CtorGen_CtorGen_overload0 >,
    bondage::FunctionBuilder::buildCall< std::tuple< ::Gen::CtorGen *, int >(*)(), &Gen_CtorGen_CtorGen_overload1 >
    >("CtorGen")
};

BONDAGE_IMPLEMENT_EXPOSED_CLASS(
  g_bondage_library,
  ::Gen::CtorGen,
  Gen_CtorGen_methods);
