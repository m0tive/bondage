-- Class Test.Bar
local Bar_cls = class "Bar" {
  Bar = internal.getNative("Test", "Bar"),
  test = internal.getNative("Test", "test"),
  test2 = internal.getNative("Test", "test2")
}

return Bar_cls