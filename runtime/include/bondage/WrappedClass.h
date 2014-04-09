#pragma once
#include "bondage/Bondage.h"
#include "Crate/Type.h"
#include "Crate/Traits.h"
#include "bondage/Function.h"

#define BONDAGE_IMPLEMENT_EXPOSED_CLASS(varName, lib, parent, name, fns, fnCount) \
  namespace Crate { namespace detail { \
  const Type *TypeResolver<parent::name>::find() \
    { static Type t(#name); return &t; } } } \
  bondage::WrappedClass varName ( \
    lib, \
    Crate::findType<parent::name>(), \
    fns, \
    fnCount); \
  const bondage::WrappedClass *bondage::WrappedClassFinder<parent::name>::findBase() \
    { return &varName; }

namespace bondage
{

class Library;

class BONDAGE_EXPORT WrappedClass
  {
public:
  WrappedClass(Library &owningLib, const Crate::Type *type, const Function *fn, std::size_t count);

  const Crate::Type &type() const;

  const Function &function(std::size_t i) const { return m_functions[i]; }
  size_t functionCount() const { return m_functionCount; }

  void setNext(WrappedClass *cls);
  const WrappedClass *next() const { return m_next; }
  WrappedClass *next() { return m_next; }

private:
  const Crate::Type *m_type;
  const Function *m_functions;
  std::size_t m_functionCount;

  WrappedClass *m_next;
  };


#ifdef REFLECT_MACRO_IMPL

template <typename T> class WrappedClassHelper
  {
public:
  typedef Crate::Traits<T> Traits;

  static T *create()
    {
    return new T();
    }

  template <typename A> static T *create(A &&a)
    {
    return new T(std::forward<A>(a));
    }

  template <typename A, typename B> static T *create(A &&a, B &&b)
    {
    return new T(std::forward<A>(a), std::forward<Args>(b));
    }

  template <typename A, typename B, typename C> static T *create(A &&a, B &&b, C &&c)
    {
    return new T(std::forward<A>(a), std::forward<Args>(b), std::forward<Args>(c));
    }
  };

#else

template <typename T> class WrappedClassHelper
  {
public:
  typedef Crate::Traits<T> Traits;

  template <typename... Args> static T *create(Args &&... args)
    {
    return new T(std::forward<Args>(args)...);
    }
  };

#endif

template <typename T> class WrappedClassFinder;

}
