#pragma once
#include "bondage/Function.h"
#include "Reflect/WrappedFunction.h"
#include "Reflect/MethodInjectorBuilder.h"

namespace bondage
{

class FunctionBuilder
  {
public:
  template <typename Fn> static Function build(const char *name)
    {
    typedef typename Fn::Binder Binder;
    typedef typename Binder::Builder Builder;

    typedef typename Fn::Caller Invoker;

    return Function(name, Invoker::template buildCall<Builder>());
    }



  template <typename Signature, Signature Fn> class buildCall
    {
  public:
    typedef Reflect::WrappedFunction<Signature, Fn> Binder;
    typedef FunctionCaller Caller;
    };

  template <typename Signature, Signature Fn> class buildMemberStandinCall
    {
    typedef Reflect::WrappedFunction<Signature, Fn> Binder;
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
