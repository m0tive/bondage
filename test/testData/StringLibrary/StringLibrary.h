#pragma once
#include <string>
#include <algorithm>

namespace String
{

#define STRING_EXPORT

/// \expose
class StringCls
{
public:
  static StringCls create(const char *val)
  {
    StringCls s;
    s.val = val;
    return s;
  }

  StringCls toUpper()
  {
    StringCls s = *this;
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

  void append(int num, int num2)
    {
    val += std::to_string(num) + std::to_string(num2);
    }

  std::string val;
};

/// \expose
inline void quote(StringCls& s)
  {
  s.val = "`" + s.val + "`";
  }

}
