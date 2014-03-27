#pragma once
#include "bondage/Function.h"
#include "Reflect/FunctionBuilder.h"
#include "Reflect/MethodInjectorBuilder.h"

namespace bondage
{

class FunctionBuilder
  {
public:
  template <typename Fn> static Function build(const char *)
    {
    typename Fn::binder bind;

    return bind.template buildInvocation<typename Fn::Caller>();
    }

  template <typename... Overloads> static Function buildOverloaded(const char *)
    {
    return Function(nullptr);
    }


  template <typename Signature, Signature Fn> class buildCall
    {
  public:
    typedef Reflect::FunctionBuilder<Signature, Fn> binder;
    typedef FunctionCaller Caller;
    };

  template <typename Signature, Signature Fn> class buildMemberStandinCall
    {
    typedef Reflect::FunctionBuilder<Signature, Fn> binder;
    typedef Reflect::MethodInjectorBuilder<FunctionCaller> Caller;
    };
  };

}
