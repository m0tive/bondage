namespace Enum
{

/// \expose
enum ExposedEnumStatic
{
  A = 5,
  B = 10,
  C = 1
};

enum Test2
{
  S, I, O
};

/// \expose
class ExposedClass
{
  /// \expose
  enum ExposedEnum
  {
    X,
    Y,
    Z
  };

  enum Test
  {
    F, e, R
  };

  void fn1(ExposedEnumStatic a);
  void fn2(Test2 a);
  void fn3(ExposedEnum a);
  void fn4(Test a);
};

}