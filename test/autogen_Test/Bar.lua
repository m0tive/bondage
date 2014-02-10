local Foo_cls = require "Foo"-- \brief Bar is a thing with stuff
--
local Bar_cls = class "Bar" {
  super = Foo_cls,

  Bar = internal.getNative("Test", "Bar"),

  getAFoo = internal.getNative("Test", "getAFoo"),

  getAVec = internal.getNative("Test", "getAVec"),

  test = internal.getNative("Test", "test"),

  test2 = internal.getNative("Test", "test2")
}

return Bar_cls