#include "bondage/WrappedClass.h"
#include "bondage/Library.h"

namespace bondage
{

WrappedClass::WrappedClass(Library &owningLib, const Reflect::Type *type, const Function *fn, std::size_t count)
    : m_type(type),
      m_functions(fn),
      m_functionCount(count)
  {
  owningLib.registerClass(this);
  }

const Reflect::Type *WrappedClass::type() const
  {
  return m_type;
  }

const Function *WrappedClass::functions() const
  {
  return m_functions;
  }

size_t WrappedClass::functionCount()
  {
  return m_functionCount;
  }

}
