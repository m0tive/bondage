#pragma once
#include "bondage/Function.h"
#include "Reflect/WrappedFunction.h"
#include "Reflect/FunctionSelector.h"
#include "Reflect/MethodInjectorBuilder.h"

namespace bondage
{

#define BONDAGE_BUILD_CALL(SIG, NAME) \
  Reflect::detail::CallHelper<Reflect::detail::FunctionHelper<SIG>, NAME, bondage::FunctionCaller>

#define BONDAGE_BUILD_MEMBER_STANDIN_CALL(SIG, NAME) \
  Reflect::detail::CallHelper<Reflect::detail::FunctionHelper<SIG>, NAME, Reflect::MethodInjectorBuilder<Fbondage::unctionCaller>>

class FunctionBuilder
  {
public:
  template <typename Fn> static Function build(const char *name)
    {
    typedef typename Fn::Caller Invoker;

    return Function(name, Invoker::template buildWrappedCall<Fn, FunctionCaller>());
    }

  template <typename Fn> static Function buildOverload(const char *name)
    {
    return Function(name, FunctionCaller::template buildWrappedCall<Fn, FunctionCaller>());
    }
  };

}
