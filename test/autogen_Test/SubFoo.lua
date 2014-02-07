-- \brief Test Sub Foo, is contained withing foo!
--
local SubFoo_cls = class "SubFoo" {

  getX = internal.getNative("Test", "getX"),

  -- \brief allows setting of x, or course
  setX = internal.getNative("Test", "setX")
}

return SubFoo_cls