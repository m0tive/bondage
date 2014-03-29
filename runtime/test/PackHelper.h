#pragma once

#include "../example/Default/Builder.h"

class BondageTestBuilder : public Reflect::example::Builder
  {
public:
  typedef Reflect::example::Boxer Boxer;

  struct Result
    {
    typedef void (*Signature)(CallData);
    Signature fn;
    };

  template <typename Builder> static Result build()
    {
    Result r = { call<Builder> };
    return r;
    }

  template <typename Builder> static void call(CallData data)
    {
    Builder::call(data);
    }
  };


namespace bondage
{
class Builder : public BondageTestBuilder { };
};
