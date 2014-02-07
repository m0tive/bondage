-- Class Test.Foo
local Foo_cls = class "Foo" {
  bar = internal.getNative("Test", "bar")
}

return Foo_cls