local Foo_cls = require "Foo"-- \brief Bar is a thing with stuff
--
local Bar_cls = class "Bar" {
  super = Foo_cls,

  -- \brief construct a bar from some sweet int
  Bar = internal.getNative("Test", "Bar"),

  -- \brief get some foo
  getAFoo = internal.getNative("Test", "getAFoo"),

  -- \brief get some vec
  getAVec = internal.getNative("Test", "getAVec"),

  -- \brief test stuff, from Bar*
  test = internal.getNative("Test", "test"),

  -- \brief get a porky list from some types
  -- \brief something else overloaded
  test2 = internal.getNative("Test", "test2")
}

return Bar_cls