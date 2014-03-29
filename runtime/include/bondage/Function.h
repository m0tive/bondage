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

  Function(Call fn)
      : m_function(fn)
    {
    }

  void call(bondage::Builder::Boxer *b, Arguments *a)
    {
    m_function(b, a);
    }

private:
  Call m_function;
  };

class FunctionCaller : public bondage::Builder
  {
public:
  typedef Function Result;

  template <typename Builder> static Result build()
    {
    return Function(call<Builder>);
    }

  template <typename Builder> static void call(Boxer *b, Function::Arguments *args)
    {
    Call data = { args, b };
    Builder::call(&data);
    }
  };

}
