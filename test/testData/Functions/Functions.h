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

  // B is not exposed, but has a default. some of this method should be available.
  /// \param[out] out a param
  void complex1(TestC *out, TestB *b = nullptr);

  // out is an input - but only partially exposed, so this is not exposed
  /// \param[in,out] out a param
  void complex2(TestC *out);

  // out has a default, so this is exposed
  /// \expose
  void complex3(TestC *out=nullptr);

  // test c is an output, so is exposed.
  /// \param[out] out output
  void complex4(TestC **out);

  // primitive pointers to pointers are not exposed
  /// \param[out] out output
  void complex5(int **out);

  // pointers to pointers are not exposed for classes (unless outputs.)
  void complex6(TestC **out);

  // triple pointers are banned
  /// \param[out] out a param
  void complex7(TestC ***out);

  // pointers to references should be exposed.
  /// \param[out] out a param
  void complex8(TestC *&out);
};

}