//  Copyright me, fool. No, copying and stuff.
// 		
//  This file is auto generated, do not change it!
// 

// Exposing class ::Test::Foo

const cobra::function Test_Foo_methods[] = {
  cobra::function_builder::build<&::Test::Foo::bar>("bar")
};

COBRA_IMPLEMENT_EXPOSED_CLASS(
  ::Test::Foo, 
  Test_Foo_methods)


// Exposing class ::Test::Foo::SubFoo

const cobra::function Test_Foo_SubFoo_methods[] = {
  cobra::function_builder::build<&::Test::Foo::SubFoo::getX>("getX"),
  cobra::function_builder::build<&::Test::Foo::SubFoo::setX>("setX")
};

COBRA_IMPLEMENT_EXPOSED_CLASS(
  ::Test::Foo::SubFoo, 
  Test_Foo_SubFoo_methods)


// Exposing class ::Test::Detail::Bar

const cobra::function Test_Detail_Bar_methods[] = {
  cobra::function_builder::build<&::Test::Detail::Bar::Bar>("Bar"),
  cobra::function_builder::build<&::Test::Detail::Bar::getAFoo>("getAFoo"),
  cobra::function_builder::build<&::Test::Detail::Bar::getAVec>("getAVec"),
  cobra::function_builder::build_overloaded<
    &::Test::Detail::Bar::test,
    &::Test::Detail::Bar::test>("test"),
  cobra::function_builder::build_overloaded<
    &::Test::Detail::Bar::test2,
    &::Test::Detail::Bar::test2>("test2")
};

COBRA_IMPLEMENT_DERIVED_EXPOSED_CLASS(
  ::Test::Detail::Bar, 
  Test_Detail_Bar_methods, 
  ::Test::Foo)


