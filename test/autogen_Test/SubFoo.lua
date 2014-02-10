--  Copyright me, fool. No, copying and stuff.
-- 		
--  This file is auto generated, do not change it!
-- 


-- \brief Test Sub Foo, is contained withing foo, it does not derive from foo.
--
local SubFoo_cls = class "SubFoo" {

  -- float SubFoo:getX()
  -- \brief get x
  getX = internal.getNative("Test", "getX"),

  -- nil SubFoo:setX(float x)
  -- \brief allows setting of x, or course
  -- \param x X value to setX
  setX = internal.getNative("Test", "setX")
}

return SubFoo_cls