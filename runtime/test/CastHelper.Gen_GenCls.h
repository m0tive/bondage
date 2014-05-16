#pragma once

namespace Crate
{

template <typename Derived> class CastHelper<Gen::GenCls, Derived>
  {
public:
  typedef Traits<Gen::GenCls> RootTraits;

  static bool canCast(const Gen::GenCls *root)
    {
    auto cast = dynamic_cast<const Derived*>(root);

    return cast != nullptr;
    }
  };

}
