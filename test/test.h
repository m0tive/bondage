#pragma once
#include "test_2.h"
#include "example.h"
#include "example_manual.h"

namespace Test
{
template<typename T> class List;

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

  const std::pork::vector<Foo> test2(int x, float y);
  std::pork::test test2(int x);
  
  void test(const Test<Foo>& = Test<Foo>()) const;
  List<int> test(Bar ** = nullptr) const;
  void test(Bar *) const;
  void test(nullptr_t) const;
};

}

}