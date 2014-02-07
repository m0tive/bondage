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

/// \brief Bar is a thing with stuff
/// \expose
class PORK Bar : public Foo, public SuperSuper<Foo>
{
public:
  /// \brief construct a bar from some sweet int
  Bar(int a);
  ~Bar();

  /// \brief get a porky list from some types
  const std::pork::vector<Foo> test2(int x, float y);
  /// \brief something else overloaded
  std::pork::test test2(int x);

  /// \brief get some foo
  NotExposedFoo* getAFoo();
  /// \brief get some vec
  NotExposedVec* getAVec();
  
  /// \brief test stuff
  void test(const Test<Foo>& = Test<Foo>()) const;
  /// \brief test stuff, from Bar**
  List<int> test(Bar ** = nullptr) const;
  /// \brief test stuff, from Bar*
  void test(Bar *) const;
  void test(nullptr_t) const;
};

}

}