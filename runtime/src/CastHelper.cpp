#include "bondage/CastHelper.h"

namespace bondage
{

CastHelper::CastHelper()
  {
  }

void CastHelper::install(CastHelperLibrary *lib)
  {
  lib->setNext(m_first);
  m_first = lib;
  }

const WrappedClass *CastHelper::search(const void *p)
  {
  for (auto d = m_first; d; d = d->next())
    {
    auto cls = d->function()(p);
    if (cls)
      {
      return cls;
      }
    }

  return nullptr;
  }

void CastHelperLibrary::setNext(CastHelperLibrary *next)
  {
  m_next = next;
  }

}
