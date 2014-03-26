#pragma once

namespace Crate
{

template <typename Derived> class CastHelper<Gen::Gen, Derived>
  {
public:
  typedef Traits<Gen::Gen> RootTraits;

  static bool canCast(const Gen::Gen *root)
    {
    auto cast = dynamic_cast<const Derived*>(root);

    return cast != nullptr;
    }
  };

}
