#pragma once
#include "bondage/Bondage.h"
#include "WrappedClass.h"

namespace bondage
{

class BONDAGE_EXPORT Library
  {
public:
  Library(const char *name);

  void registerClass(WrappedClass *cls);

  const WrappedClass *firstClass() const
    {
    return m_first;
    }

private:
  WrappedClass *m_first;
  WrappedClass *m_last;
  std::string m_name;
  };

class BONDAGE_EXPORT ClassWalker
  {
public:
  ClassWalker(const Library &l);

  class iterator
    {
  public:
    iterator(const WrappedClass *cls);
    const WrappedClass *operator*() const;
    bool operator!=(const iterator &i) const;
    iterator& operator++();

  private:
    const WrappedClass *m_cls;
    };

  iterator begin();
  iterator end();

private:
  const Library *m_library;
  };

}
