#pragma once
#include "test_2.h"

namespace Test
{
namespace Detail
{
	
template <typename T> const Foo &fooer();

template <typename X> class SuperSuper
{
};

// Test
class PORK Bar : private Foo, public SuperSuper<Foo>
{
  Bar(int a);
  ~Bar();
  
  void test(const Test<Foo>& = Test<Foo>()) const;
};

}

}