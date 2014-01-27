// Exposing class ::Test::Foo

const cobra::function Test_Foo_methods[] = {
  cobra::function_builder::build<&::Test::Foo::bar>("bar"),
  cobra::function_builder::build<&::Test::Foo::cake>("cake")
};

COBRA_IMPLEMENT_EXPOSED_CLASS(::Test::Foo, Test_Foo_methods)


// Exposing class ::Test::Foo::SubFoo

const cobra::function Test_Foo_SubFoo_methods[] = {
  cobra::function_builder::build<&::Test::Foo::SubFoo::getX>("getX"),
  cobra::function_builder::build<&::Test::Foo::SubFoo::setX>("setX")
};

COBRA_IMPLEMENT_EXPOSED_CLASS(::Test::Foo::SubFoo, Test_Foo_SubFoo_methods)


// Exposing class ::Test::Detail::Bar

const cobra::function Test_Detail_Bar_methods[] = {
  cobra::function_builder::build<&::Test::Detail::Bar::Bar>("Bar"),
  cobra::function_builder::build<&::Test::Detail::Bar::test>("test")
};

COBRA_IMPLEMENT_EXPOSED_CLASS(::Test::Detail::Bar, Test_Detail_Bar_methods)


