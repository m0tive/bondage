#pragma once

#include "Bondage.h"

namespace bondage
{

class WrappedClass;
class CastHelperLibrary;

class CastHelper
  {
public:
  CastHelper();

  void install(CastHelperLibrary *lib);
  const WrappedClass *search(const void *);

private:
  CastHelperLibrary *m_first;
  };

class BONDAGE_EXPORT CastHelperLibrary
  {
public:
  typedef const WrappedClass *(*SearchFunction)(const void *);

   CastHelperLibrary(CastHelper &helper, SearchFunction fn)
      : m_function(fn)
    {
    helper.install(this);
    }

  void setNext(CastHelperLibrary *next);
  CastHelperLibrary *next() { return m_next; }

  SearchFunction function() const { return m_function; }

private:
  SearchFunction m_function;
  CastHelperLibrary *m_next;
  };

}
