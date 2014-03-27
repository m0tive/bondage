#pragma once

namespace bondage
{

class Function
  {
public:
  class Arguments
    {
  public:
    void **_args;
    void *_this;
    void *_result;
    };
  typedef Arguments *CallData;

  typedef void (*Call)(Arguments *);

  Function(Call fn)
      : m_function(fn)
    {
    }

  void call(Arguments *a)
    {
    m_function(a);
    }

private:
  Call m_function;
  };

class FunctionCaller
  {
public:
  typedef Function::Arguments *CallData;
  typedef Function Result;

  template <typename Builder> static Result build()
    {
    return Function(call<Builder>);
    }

  template <typename Builder> static void call(CallData data)
    {
    Builder::call(data);
    }


  template <typename T> static T getThis(CallData args)
    {
    return (T)args->_this;
    }

  template <std::size_t I, typename Arg>
      static Arg unpackArgument(CallData args)
    {
    typedef typename std::remove_reference<Arg>::type NoRef;
    return *(NoRef*)args->_args[I];
    }

  template <typename Return, typename T> static void packReturn(CallData data, T &&result)
    {
    *(Return*)data->_result = result;
    }
  };

}
