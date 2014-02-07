-- \brief Foo allows people to do foo like things
--
local Foo_cls = class "Foo" {

  -- \brief invokes barr-iness.
  bar = internal.getNative("Test", "bar")
}

return Foo_cls