#pragma once
#include "bondage/Bondage.h"
#include "WrappedClass.h"

namespace bondage
{

class BONDAGE_EXPORT Library
  {
public:
  Library(const char *name, const Function *functions, std::size_t functionCount);

  void registerClass(WrappedClass *cls);

  const WrappedClass *firstClass() const
    {
    return m_first;
    }

  const Function &function(std::size_t i) const { return m_functions[i]; }
  size_t functionCount() const { return m_functionCount; }

private:
  WrappedClass *m_first;
  WrappedClass *m_last;
  std::string m_name;

  const Function *m_functions;
  std::size_t m_functionCount;
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
