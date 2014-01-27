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

/// Test
/// \expose
class PORK Bar : private Foo, public SuperSuper<Foo>
{
  Bar(int a);
  ~Bar();
  
  void test(const Test<Foo>& = Test<Foo>()) const;
  void test(Bar ** = nullptr) const;
  void test(Bar *) const;
  void test(nullptr_t) const;
};

}

}