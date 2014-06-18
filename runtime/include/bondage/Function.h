#pragma once
#include "PackHelper.h"

namespace bondage
{

class Function
  {
public:
  typedef bondage::Builder::Arguments Arguments;
  typedef bondage::Builder::Call Call;
  typedef bondage::Builder::CanCall CanCall;
  typedef Arguments *CallData;

  Function(const char *name, Call fn)
      : m_function(fn),
        m_name(name)
    {
    assert(m_function);
    }

  Call getCallFunction()
    {
    return m_function;
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

  template <typename Function, typename Builder> static Result buildWrappedCall()
    {
    return wrapCall<Function, Builder>;
    }

  template <typename Function, typename Builder> static CanCallResult buildWrappedCanCall()
    {
    return wrapCanCall<Function, Builder>;
    }

  template <typename Fn, typename Builder> static void call(Boxer *b, Function::Arguments *data)
    {
    auto call = bondage::Builder::buildCall<Fn>(data, b);
    Fn::template call<Builder>(&call);
    }

  template <typename Fn, typename Builder> static bool canCall(Boxer *b, Function::Arguments *data)
  {
    auto call = bondage::Builder::buildCall<Fn>(data, b);
    return Fn::template canCall<Builder>(&call);
  }
  };

}
