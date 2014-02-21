namespace Functions
{

/// \expose
class TestA
{
};

class TestB
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
};

}