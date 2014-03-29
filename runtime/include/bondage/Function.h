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

  Function(const char *name, Call fn)
      : m_function(fn),
        m_name(name)
    {
    }

  void call(bondage::Builder::Boxer *b, Arguments *a)
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

  template <typename Builder> static Result build()
    {
    return call<Builder>;
    }

  template <typename Builder> static void call(Boxer *b, Function::Arguments *args)
    {
    Call data = { args, b };
    Builder::call(&data);
    }
  };

}
