#pragma once
#include "Crate/BaseTraits.h"

namespace Crate
{

/// \brief ReferenceTraits stores a pointer of a class in memory owned by the receiver.
  template <typename T> class DerivableTraits : public BaseTraits<T, DerivableTraits<T>>
  {
  public:
  typedef std::integral_constant<bool, true> Managed;

  typedef std::integral_constant<size_t, sizeof(T*)> TypeSize;
  typedef std::integral_constant<size_t, std::alignment_of<T*>::value> TypeAlignment;

  typedef BaseTraits<T, DerivableTraits<T>> Base;

  template <typename Box> static T **getMemory(Box *ifc, typename Box::BoxedData data)
    {
    return static_cast<T **>(ifc->getMemory(data));
    }

  template<typename Box> static T *unbox(Box *ifc, typename Box::BoxedData data)
    {
    Base::checkUnboxable(ifc, data);

    return *getMemory(ifc, data);
    }

  template <typename Box> static void cleanup(Box *ifc, typename Box::BoxedData data)
    {
    T *mem = unbox(ifc, data);
    delete mem;
    }

  template<typename Box> static void box(Box *ifc, typename Box::BoxedData data, T *dataIn)
    {
    auto& helper = bondage::WrappedClassFinder<T>::castHelper();
    const bondage::WrappedClass* wrapper = helper.search(dataIn);
    const Crate::Type* type = wrapper ? &wrapper->type() : Base::getType();

    if (ifc->template initialise<DerivableTraits<T>, T>(data, type, dataIn, cleanup<Box>) == Base::AlreadyInitialised)
      {
      return;
      }

    T **memory = getMemory(ifc, data);
    *memory = dataIn;
    }
  };

}
