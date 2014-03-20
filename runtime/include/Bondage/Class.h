#pragma once
#include "Reflect/Type.h"
#include "Bondage/Function.h"
#include "Bondage/Boxer.h"

#define BONDAGE_ARRAY_COUNT(arr) (sizeof(arr)/sizeof(arr[0]))
#define BONDAGE_IMPLEMENT_EXPOSED_CLASS(name, fns) bondage::wrapped_class class_##fns (Reflect::findType<name>(), fns, BONDAGE_ARRAY_COUNT(fns))

namespace bondage
{

class wrapped_class
  {
public:
  wrapped_class(const Reflect::Type *type, const function *fn, std::size_t count)
      : m_type(type),
        m_functions(fn),
        m_functionCount(count)
    {
    }

  const Reflect::Type *type() const
    {
    return m_type;
    }

  const function *functions() const
    {
    return m_functions;
    }

  size_t functionCount()
    {
    return m_functionCount;
    }

private:
  const Reflect::Type *m_type;
  const function *m_functions;
  size_t m_functionCount;
  };

template <typename T> class wrapped_class_helper
  {
public:
  typedef Crate::Traits<T> Traits;

  template <typename... Args> static T *create(Args &&... args)
    {
    return new T(std::forward<Args>(args)...);
    }
  };

}
