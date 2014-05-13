// Copyright me, fool. No, copying and stuff.
//
// This file is auto generated, do not change it!
//

#pragma once
#include "Generator.h"
#include "bondage/RuntimeHelpers.h"

namespace Gen
{
GEN_EXPORT const bondage::Library &bindings();
}

BONDAGE_EXPOSED_CLASS_COPYABLE(::Gen::CtorGen)
BONDAGE_EXPOSED_CLASS_COPYABLE(::Gen::MultipleReturnGen)
BONDAGE_EXPOSED_CLASS_DERIVABLE_MANAGED(::Gen::Gen)
BONDAGE_EXPOSED_DERIVED_CLASS(::Gen::InheritTest, ::Gen::Gen, ::Gen::Gen)
BONDAGE_EXPOSED_DERIVED_CLASS(::Gen::InheritTest2, ::Gen::InheritTest, ::Gen::Gen)
BONDAGE_EXPOSED_ENUM(::Gen::InheritTest2::MyEnum)
BONDAGE_EXPOSED_ENUM(::Gen::GlbEnum)
