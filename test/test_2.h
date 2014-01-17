#pragma once

namespace Test
{

int tst();

struct
{
  virtual void a() = 0;

  union
  {
    int a;
    float b;
  };
};

#define PORK
/// \brief Test Foo
class PORK Foo
{
  /// \brief Test Sub Foo
  class SubFoo // Test
  {
    /// \brief Test SetX
    /// \param x X value to setX
    void setX(float x);
    float x;
  };
  
  enum pork
  {
    PORK,
    PIE
  };
  
  /// \brief Test bar method
  /// \param cake gives much cake.
  pork bar(int cake, float pork = 4.5);
  
private:
  // test.
  int cake()
  {
    printf("");
    
    Pork<tmp>();
  }

  template <typename T> class XXX
  {
  };

  template <typename X> void foo2(int = tst());
};

template <typename T> class Test
{
  template <typename X> void pork()
  {
  }
};

}