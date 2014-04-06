#pragma once
#include "PackHelper.h"

namespace bondage
{

class Function
  {
public:
  typedef bondage::Builder::Arguments Arguments;
  typedef Arguments *CallData;

  typedef void (*Call)(bondage::Builder::Boxer *, Arguments *);
  typedef bool (*CanCall)(bondage::Builder::Boxer *, Arguments *);

  Function(const char *name, Call fn)
      : m_function(fn),
        m_name(name)
    {
    assert(m_function);
    }

  void call(bondage::Builder::Boxer *b, Arguments *a) const
    {
    m_function(b, a);
    }

  const std::string &name() const { return m_name; }

private:
  Call m_function;
  std::string m_name;
  };

class FunctionCaller : public bondage::Builder
  {
public:
  typedef Function::Call Result;
  typedef Function::CanCall CanCallResult;

  template <typename Function, typename Builder=FunctionCaller> static Result buildCall()
    {
    return call<Function, Builder>;
    }

  template <typename Function, typename Builder=FunctionCaller> static CanCallResult buildCanCall()
    {
    return canCall<Function, Builder>;
    }

  template <typename Fn, typename Builder=FunctionCaller> static void call(Boxer *b, Function::Arguments *data)
    {
    Call call = { data, b };
    Fn::template call<Builder>(&call);
    }

  template <typename Fn, typename Builder=FunctionCaller> static bool canCall(Boxer *b, Function::Arguments *data)
    {
    Call call = { data, b };
    return Fn::template canCall<Builder>(&call);
    }
  };

}
