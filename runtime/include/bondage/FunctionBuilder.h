#pragma once
#include "bondage/Function.h"

namespace bondage
{

class function_builder
  {
public:
  template <typename Fn> static function build(const char *)
    {
    return function();
    }

  template <typename... Overloads> static function build_overloaded(const char *)
    {
    return function();
    }


  template <typename Signature, Signature Fn> class build_call
    {
    };

  template <typename Signature, Signature Fn> class build_member_standin_call
    {
    };
  };

}
