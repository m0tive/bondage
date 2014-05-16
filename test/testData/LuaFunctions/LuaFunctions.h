
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
  
  bool operator==(float) const;
  bool operatorPork();
};

/// \expose
struct TestClassIndexed
{
public:
  short luaSample();
  /// \brief sample
  /// \param idx [index] the Index
  /// \return [index] returns an index
  short luaSample(int idx);
  /// \brief sample
  /// \return [index]
  short luaSample(int idx, float);
  /// \brief sample
  /// \param[out] idx2 [index] the Index2
  /// \param idx3 [index] the Index2
  /// \param[out] out2 sweet output
  /// \return [index] the result
  static short luaSample(int idx, double a, float b, int &idx2, const int &idx3, float *out2);


  /// \return [index]
  TestClassIndexed &luaSample2();
};


void testFunction();
}