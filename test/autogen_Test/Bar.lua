local Foo_def = require "Foo"

-- Class Test.Bar
local Bar_cls = class "Bar" {
  super = Foo_def,

  Bar = internal.getNative("Test", "Bar"),
  getAFoo = internal.getNative("Test", "getAFoo"),
  getAVec = internal.getNative("Test", "getAVec"),
  test = internal.getNative("Test", "test"),
  test2 = internal.getNative("Test", "test2")
}

return Bar_cls