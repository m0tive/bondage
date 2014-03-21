#pragma once
#include "WrappedClass.h"

namespace bondage
{

class Library
  {
public:
  Library();

  void registerClass(WrappedClass *cls);

private:
  WrappedClass *m_first;
  };

}
