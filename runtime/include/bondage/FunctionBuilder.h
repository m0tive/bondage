#pragma once
#include "bondage/Function.h"
#include "Reflect/FunctionBuilder.h"
#include "Reflect/MethodInjectorBuilder.h"

namespace bondage
{

class FunctionBuilder
  {
public:
  template <typename Fn> static Function build(const char *name)
    {
    typename Fn::binder bind;

    return Function(name, bind.template buildInvocation<typename Fn::Caller>());
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



  template <typename Functions> static Function buildArgumentCountOverload(const char *name)
    {
    return Function(name, nullptr);
    }

  template <std::size_t _Count, typename _Functions> class buildOverloaded
    {
  public:
    typedef std::integral_constant<std::size_t, _Count> Count;
    typedef _Functions Functions;

    };
  };

}
