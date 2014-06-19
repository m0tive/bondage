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

  Call getCallFunction() const
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
  };

}
