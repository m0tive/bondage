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

  typedef Result::Signature Call;
  typedef bool (*CanCall)(CallData);

  template <typename Builder> static Result build()
    {
    Result r = { wrapCall<Builder> };
    return r;
    }

  template <typename Function, typename Builder> static void wrapCall(CallData data)
    {
    Function::template call<Builder>(data);
    }

  template <typename Function, typename Builder> static void wrapCanCall(CallData data)
    {
    Function::template canCall<Builder>(data);
    }
  };


namespace bondage
{
class Builder : public BondageTestBuilder { };
};
