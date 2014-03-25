#pragma once
#include "Crate/Traits.h"
#include "bondage/Library.h"

#define BONDAGE_CLASS_RESOLVER(CLS) \
  namespace Reflect { \
  namespace detail { \
  template <> struct TypeResolver<CLS> { \
  static const Type *find(); }; } }


#define BONDAGE_CLASS_CRATER(CLS, TRAITS) \
  namespace Crate { template <> class Traits<CLS> : public TRAITS<CLS> { }; }

#define BONDAGE_CLASS_DERIVABLE(CLS)

#define BONDAGE_EXPOSED_CLASS_COPYABLE(CLS) \
  BONDAGE_CLASS_RESOLVER(CLS) \
  BONDAGE_CLASS_CRATER(CLS, CopyTraits)

#define BONDAGE_EXPOSED_CLASS_MANAGED(CLS) \
  BONDAGE_CLASS_RESOLVER(CLS) \
  BONDAGE_CLASS_CRATER(CLS, ReferenceTraits)

#define BONDAGE_EXPOSED_CLASS_UNMANAGED(CLS) \
  BONDAGE_CLASS_RESOLVER(CLS) \
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
  namespace Crate { template <> class Traits<CLS> : public DerivedTraits<CLS, PARENT, ROOT> { }; }
