#pragma once
#include "Crate/Traits.h"
#include "bondage/Library.h"
#include "bondage/CastHelper.h"

namespace bondage
{
class WrappedClass;
class CastHelper;
}

#define BONDAGE_CLASS_RESOLVER(CLS) \
  namespace Reflect { \
  namespace detail { \
  template <> struct TypeResolver<CLS> { \
  static const Type *find(); }; } }

#define BONDAGE_CLASS_UNDERIVABLE(CLS) namespace bondage { \
  template <> class WrappedClassFinder<CLS> { public: \
    static const WrappedClass *findBase(); \
    static const WrappedClass *find(const void *) { return findBase(); } }; }

#define BONDAGE_CLASS_DERIVABLE(CLS) namespace bondage { \
  template <> class WrappedClassFinder<CLS> { public: \
    static const WrappedClass *findBase(); \
    static CastHelper &castHelper() { static CastHelper data; return data; } \
    static const WrappedClass *find(const void *d) \
      { auto cls = castHelper().search(d); \
      if (cls) { return cls; } \
      return findBase(); } }; }

#define BONDAGE_CLASS_DERIVED(CLS, ROOT) namespace bondage { \
  template <> class WrappedClassFinder<CLS> { public: \
    static const WrappedClass *findBase(); \
    static const WrappedClass *find(const void *p) \
      { return WrappedClassFinder<ROOT>::find(p); } }; }

#define BONDAGE_CLASS_CRATER(CLS, TRAITS) \
  namespace Crate { template <> class Traits<CLS> : public TRAITS<CLS> { }; }


#define BONDAGE_EXPOSED_CLASS_COPYABLE(CLS) \
  BONDAGE_CLASS_RESOLVER(CLS) \
  BONDAGE_CLASS_UNDERIVABLE(CLS) \
  BONDAGE_CLASS_CRATER(CLS, CopyTraits)

#define BONDAGE_EXPOSED_CLASS_MANAGED(CLS) \
  BONDAGE_CLASS_RESOLVER(CLS) \
  BONDAGE_CLASS_UNDERIVABLE(CLS) \
  BONDAGE_CLASS_CRATER(CLS, ReferenceTraits)

#define BONDAGE_EXPOSED_CLASS_UNMANAGED(CLS) \
  BONDAGE_CLASS_RESOLVER(CLS) \
  BONDAGE_CLASS_UNDERIVABLE(CLS) \
  BONDAGE_CLASS_CRATER(CLS, ReferenceNonCleanedTraits)

#define BONDAGE_EXPOSED_CLASS_DERIVABLE_MANAGED(CLS) \
  BONDAGE_CLASS_RESOLVER(CLS) \
  BONDAGE_CLASS_DERIVABLE(CLS) \
  BONDAGE_CLASS_CRATER(CLS, ReferenceTraits)

#define BONDAGE_EXPOSED_CLASS_DERIVABLE_UNMANAGED(CLS) \
  BONDAGE_CLASS_RESOLVER(CLS) \
  BONDAGE_CLASS_DERIVABLE(CLS) \
  BONDAGE_CLASS_CRATER(CLS, ReferenceNonCleanedTraits)

#define BONDAGE_EXPOSED_DERIVED_CLASS(CLS, PARENT, ROOT) \
  BONDAGE_CLASS_RESOLVER(CLS) \
  BONDAGE_CLASS_DERIVED(CLS, ROOT) \
  namespace Crate { template <> class Traits<CLS> : public DerivedTraits<CLS, PARENT, ROOT> { }; }
