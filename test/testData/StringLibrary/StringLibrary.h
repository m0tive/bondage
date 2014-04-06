#pragma once
#include <string>
#include <algorithm>

namespace String
{

#define STRING_EXPORT

/// \expose
class String
{
public:
  static String create(const char *val)
  {
    String s;
    s.val = val;
    return s;
  }

  String toUpper()
  {
    String s = *this;
    std::transform(s.val.begin(), s.val.end(), s.val.begin(), ::toupper);
    return s;
  }

  void append(const char* str)
    {
    val += str;
    }

  void append(int num)
    {
    val += std::to_string(num);
    }

  void append(int num, float num2)
    {
    val += std::to_string(num) + std::to_string(num2);
    }

  std::string val;
};

}
