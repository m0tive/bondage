namespace Enum
{

/// \expose
enum ExposedEnumStatic
{
  A,
  B,
  C
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
};

}