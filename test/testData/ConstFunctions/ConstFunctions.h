#pragma once

namespace ConstFunctions
{

/// \expose
class ConstClass
{
public:
  float test();
  float test() const;

  void testPork();
  void testPork(float a = 5.0f) const;
};


}
