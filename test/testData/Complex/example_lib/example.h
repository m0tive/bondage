#pragma once
namespace std
{
namespace pork
{
/// \brief this is a test class, it has some pod data methods.
/// \expose
struct test
{
  void test0() const;
  int test1();
  long test2(float, double);
  const long& test3();
  const char& test4();
  const char* test5(const char*);
  const wchar_t* test6(const wchar_t*);
  const wchar_t* test7(wchar_t*);
};

}
}
