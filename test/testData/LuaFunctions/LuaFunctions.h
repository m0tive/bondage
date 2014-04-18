
namespace LuaFunctions
{

/// \expose
struct TestClass
{
public:
  void luaSample();
  void luaSample(int);
  void luaSample(float);
  void luaSample(int, float);
};

/// \expose
struct TestClassIndexed
{
public:
  short luaSample();
  /// \brief sample
  /// \param idx [index] the Index
  /// \return [index]
  short luaSample(int idx);
  /// \brief sample
  /// \return [index]
  short luaSample(int idx, float);
  /// \brief sample
  /// \param[out] idx2 [index] the Index2
  /// \param idx3 [index] the Index2
  /// \return [index]
  static short luaSample(int idx, double a, float b, int &idx2, int &idx3);


  /// \return [index]
  TestClassIndexed &luaSample2();
};


void testFunction();
}