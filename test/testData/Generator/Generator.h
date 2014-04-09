#include <cstddef>

#define GEN_EXPORT

namespace Gen
{

/// \brief A CLASS!
///
/// \expose derivable managed
class Gen
{
public:
  virtual ~Gen() { }

  /// \brief This funciton is a test
  /// \param myint This is an int!
  /// \param myFloat This is a float.
  /// \return Returns NOTHING.
  void test1(int myint, float myFloat, double)
    {
    (void)myint;
    (void)myFloat;
    }

  void test2(int, float = 2.0f, double = 4.0)
    {
    }

  static void test3(bool)
    {
    }

  static int test3(bool, int, bool = false)
    {
    return 5;
    }

  static int test3(float, float)
    {
    return 5;
    }
};

inline int test4(bool a, bool b)
  {
  (void)a;
  (void)b;
  return 3;
  }
inline int test5(bool a, bool b, float = 4.3f)
  {
  (void)a;
  (void)b;
  return 1;
  }

/// \expose
class InheritTest : public Gen
{
public:
  void pork()
    {
    }

  int pork2()
    {
    return 0;
    }
};

/// \expose
class InheritTest2 : public InheritTest
{
};

/// \expose
class MultipleReturnGen
{
public:
  /// \brief test
  /// \param[out] a test param
  /// \param[in,out] b test param
  void test(int *a = nullptr, float *b = nullptr)
    {
    *a = 3;
    *b = 2;
    }

  /// \brief test again
  /// \param[in] a test
  /// \param[in,out] b test2
  /// \param[out] c test3
  double test(int &a, int *b, int &c)
    {
    (void)a;
    (void)b;
    (void)c;
    return 2.3;
    }
};

/// \expose
class CtorGen
{
public:
  CtorGen()
    {
    }

  /// \param[out] i an Output
  CtorGen(int *i)
    {
    (void)i;
    }
};

}
