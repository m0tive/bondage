-- \brief Foo allows people to do foo like things
--
local Foo_cls = class "Foo" {

  -- Test::Foo::pork Foo:bar(int cake, float pork)
  -- \brief invokes barr-iness.
  -- \param cake gives much cake.
  bar = internal.getNative("Test", "bar")
}

return Foo_cls