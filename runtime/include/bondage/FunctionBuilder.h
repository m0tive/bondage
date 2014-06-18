#pragma once
#include "bondage/Function.h"
#include "Reflect/WrappedFunction.h"
#include "Reflect/FunctionSelector.h"
#include "Reflect/MethodInjectorBuilder.h"

namespace bondage
{

class FunctionBuilder
  {
public:
  template <typename Fn> static Function build(const char *name)
    {
    typedef typename Fn::Caller Invoker;

    return Function(name, Invoker::template buildWrappedCall<Fn, FunctionCaller>());
    }



  template <typename Signature, Signature Fn> class buildCall :
      public Reflect::WrappedFunction<Signature, Fn>::Builder
    {
  public:
    typedef FunctionCaller Caller;
    };

  template <typename Signature, Signature Fn> class buildMemberStandinCall :
      public Reflect::WrappedFunction<Signature, Fn>::Builder
    {
  public:
    typedef Reflect::MethodInjectorBuilder<FunctionCaller> Caller;
    };



  template <typename Functions> static Function buildOverload(const char *name)
    {
    return Function(name, FunctionCaller::template buildWrappedCall<Functions, FunctionCaller>());
    }
  };

}
