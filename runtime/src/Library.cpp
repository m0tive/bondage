#include "bondage/Library.h"
#include <cassert>

namespace bondage
{

Library::Library(const char *name)
    : m_name(name)
  {
  }

void Library::registerClass(WrappedClass *cls)
  {
  if (!m_first)
    {
    m_first = m_last = cls;
    return;
    }

  auto lst = m_last;
  m_last = cls;

  assert(lst);
  lst->setNext(m_last);
  }


ClassWalker::ClassWalker(const Library &l)
    : m_library(&l)
  {
  }

ClassWalker::iterator::iterator(const WrappedClass *cls)
    : m_cls(cls)
  {
  }

const WrappedClass *ClassWalker::iterator::operator*() const
  {
  return m_cls;
  }

bool ClassWalker::iterator::operator!=(const iterator &i) const
  {
  return m_cls != i.m_cls;
  }

ClassWalker::iterator& ClassWalker::iterator::operator++()
  {
  assert(m_cls);
  m_cls = m_cls->next();
  return *this;
  }

ClassWalker::iterator ClassWalker::begin()
  {
  return iterator(m_library->firstClass());
  }

ClassWalker::iterator ClassWalker::end()
  {
  return iterator(nullptr);
  }

}
