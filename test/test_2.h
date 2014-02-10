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
/// \brief Foo allows people to do foo like things
/// \expose
class PORK Foo
{
public:
  /// \brief Test Sub Foo, is contained withing foo!
  /// \expose
  class SubFoo // Test
  {
  public:
    /// \brief allows setting of x, or course
    /// \param x X value to setX
    void setX(float x);
    /// \brief get x
    /// \return The result of X
    float getX() const { return x; }

    float x;
  };
  
  enum pork
  {
    PORK,
    PIE
  };
  
  /// \brief invokes barr-iness.
  /// \param cake gives much cake.
  /// \returns lots of pork
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

template <typename T> struct   Test2
{
  template <typename X> void pork()
  {
  }
};

}