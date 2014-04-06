#include "bondage/WrappedClass.h"
#include "bondage/Library.h"
#include <cassert>

namespace bondage
{

WrappedClass::WrappedClass(Library &owningLib, const Crate::Type *type, const Function *fn, std::size_t count)
    : m_type(type),
      m_functions(fn),
      m_functionCount(count),
      m_next(nullptr)
  {
  assert(type);
  owningLib.registerClass(this);
  }

const Crate::Type &WrappedClass::type() const
  {
  return *m_type;
  }

void WrappedClass::setNext(WrappedClass *cls)
  {
  assert(!m_next);
  m_next = cls;
  }

}
