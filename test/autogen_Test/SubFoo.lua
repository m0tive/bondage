-- \brief Test Sub Foo, is contained withing foo!
--
local SubFoo_cls = class "SubFoo" {

  getX = internal.getNative("Test", "getX"),

  setX = internal.getNative("Test", "setX")
}

return SubFoo_cls