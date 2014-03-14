#include <cstddef>

namespace Gen
{

/// \expose
class Gen
{
public:
  void test1(int, float, double);
  void test2(int, float = 2.0f, double = 4.0);

  static void test3(bool);
  static int test3(bool, int, bool = false);
};

int test4(bool a, bool b);
int test5(bool a, bool b, float = 4.3f);

/// \expose
class MultipleReturnGen
{
public:
  /// \brief test
  /// \param[out] a test param
  /// \param[in,out] b test param
  void test(int *a = nullptr, float *b = nullptr);
  /// \brief test again
  /// \param[in] a test
  /// \param[in,out] b test2
  /// \param[out] c test3
  double test(int &a, int *b, int &c);
};

/// \expose
class CtorGen
{
public:
  CtorGen();
  /// \param[out] i an Output
  CtorGen(int *i);
};

}