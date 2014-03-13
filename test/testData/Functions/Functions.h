namespace Functions
{

/// \expose derivable
class TestA
{
};

class TestB
{
};

class TestC : public TestA
{

};

const TestA &testExpose1(float, bool pork);
TestA &testExpose2(TestA *a);
const TestB &testNotExpose(float, bool);

/// \expose
class SomeClass
{
public:
  void overloaded(TestA &t);
  void overloaded(TestB &t);
  void overloaded(TestA &t, int, float);
  static void overloaded(TestA *t);

  /// \param[out] out a param
  void complex(TestC *out, TestB *b = nullptr);

  /// \param[in,out] out a param
  void complex2(TestC *out);
};

}