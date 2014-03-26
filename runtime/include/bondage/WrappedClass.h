#pragma once
#include "bondage/Bondage.h"
#include "Reflect/Type.h"
#include "Crate/Traits.h"
#include "bondage/Function.h"
#include "bondage/Boxer.h"

#define BONDAGE_ARRAY_COUNT(arr) (sizeof(arr)/sizeof(arr[0]))
#define BONDAGE_IMPLEMENT_EXPOSED_CLASS(varName, lib, parent, name, fns) \
  namespace Reflect { namespace detail { \
  const Type *TypeResolver<parent::name>::find() \
    { static Type t(#name); return &t; } } } \
  bondage::WrappedClass varName (lib, Reflect::findType<parent::name>(), fns, BONDAGE_ARRAY_COUNT(fns))

namespace bondage
{

class Library;

class BONDAGE_EXPORT WrappedClass
  {
public:
  WrappedClass(Library &owningLib, const Reflect::Type *type, const Function *fn, std::size_t count);

  const Reflect::Type &type() const;

  const Function *functions() const;
  size_t functionCount();

  void setNext(WrappedClass *cls);
  const WrappedClass *next() const { return m_next; }
  WrappedClass *next() { return m_next; }

private:
  const Reflect::Type *m_type;
  const Function *m_functions;
  size_t m_functionCount;

  WrappedClass *m_next;
  };

template <typename T> class WrappedClassHelper
  {
public:
  typedef Crate::Traits<T> Traits;

  template <typename... Args> static T *create(Args &&... args)
    {
    return new T(std::forward<Args>(args)...);
    }
  };

}
