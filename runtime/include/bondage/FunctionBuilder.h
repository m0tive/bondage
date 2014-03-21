#pragma once
#include "bondage/Function.h"

namespace bondage
{

class FunctionBuilder
  {
public:
  template <typename Fn> static Function build(const char *)
    {
    return Function();
    }

  template <typename... Overloads> static Function buildOverloaded(const char *)
    {
    return Function();
    }


  template <typename Signature, Signature Fn> class buildCall
    {
    };

  template <typename Signature, Signature Fn> class buildMemberStandinCall
    {
    };
  };

}
