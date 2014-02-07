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

class NotExposedFoo : public Foo
{
};

class NotExposedVec : public std::pork::vector<Foo>
{
};

/// Test
/// \expose
class PORK Bar : private Foo, public SuperSuper<Foo>
{
public:
  Bar(int a);
  ~Bar();

  const std::pork::vector<Foo> test2(int x, float y);
  std::pork::test test2(int x);

  NotExposedFoo* getAFoo();
  NotExposedVec* getAVec();
  
  void test(const Test<Foo>& = Test<Foo>()) const;
  List<int> test(Bar ** = nullptr) const;
  void test(Bar *) const;
  void test(nullptr_t) const;
};

}

}