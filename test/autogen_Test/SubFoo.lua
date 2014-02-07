-- Class Test.SubFoo
local SubFoo_cls = class "SubFoo" {
  getX = internal.getNative("Test", "getX"),
  setX = internal.getNative("Test", "setX")
}

return SubFoo_cls