--  Copyright me, fool. No, copying and stuff.
-- 		
--  This file is auto generated, do not change it!
-- 

local Foo_cls = require "Foo"

-- \brief Bar is a thing with stuff
--
local Bar_cls = class "Bar" {
  super = Foo_cls,

  -- nil Bar:Bar(int a)
  -- \brief construct a bar from some sweet int
  Bar = internal.getNative("Test", "Bar"),

  -- Test::Detail::NotExposedFoo * Bar:getAFoo()
  -- \brief get some foo
  getAFoo = internal.getNative("Test", "getAFoo"),

  -- Test::Detail::NotExposedVec * Bar:getAVec()
  -- \brief get some vec
  getAVec = internal.getNative("Test", "getAVec"),

  -- nil Bar:test(Test::Detail::Bar * )
  -- nil Bar:test(int )
  -- \brief test stuff, from Bar*
  test = internal.getNative("Test", "test"),

  -- const std::pork::vector<Foo> Bar:test2(int x, float & y)
  -- std::pork::test Bar:test2(int x)
  -- \brief something else overloaded
  -- \param y output float after xing.
  test2 = internal.getNative("Test", "test2")
}

return Bar_cls