#pragma once
#include "Crate/BaseTraits.h"

namespace Crate
{

/// \brief ReferenceTraits stores a pointer of a class in memory owned by the receiver,
///        it will not delete the pointer when unreferenced.
template <typename T> class DerivableNonCleanedTraits : public BaseTraits<T, ReferenceNonCleanedTraits<T>>
  {
public:
  typedef std::integral_constant<bool, true> Managed;

  typedef std::integral_constant<size_t, sizeof(T*)> TypeSize;
  typedef std::integral_constant<size_t, std::alignment_of<T*>::value> TypeAlignment;

  typedef BaseTraits<T, ReferenceNonCleanedTraits<T>> Base;

  template <typename Box> static T **getMemory(Box *ifc, typename Box::BoxedData data)
    {
    return static_cast<T **>(ifc->getMemory(data));
    }

  template<typename Box> static T *unbox(Box *ifc, typename Box::BoxedData data)
    {
    Base::checkUnboxable(ifc, data);

    return *getMemory(ifc, data);
    }

  template <typename Box> static void cleanup(Box *, typename Box::BoxedData)
    {
    }

  template<typename Box> static void box(Box *ifc, typename Box::BoxedData data, T *dataIn)
  {
    auto& helper = bondage::WrappedClassFinder<T>::castHelper();
    const bondage::WrappedClass* wrapper = helper.search(dataIn);
    const Crate::Type* baseType = Base::getType();
    const Crate::Type* type = wrapper ? &wrapper->type() : baseType;

    if (ifc->template initialise<ReferenceNonCleanedTraits<T>, T>(data, baseType, type, dataIn, cleanup<Box>) == Base::AlreadyInitialised)
      {
      return;
      }

    T **memory = getMemory(ifc, data);
    *memory = dataIn;
    }
  };
}
