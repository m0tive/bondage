#include "ParentA.h"

namespace ParentB
{

/// \expose
class Q
{

};

class R : public Q
{

};

/// \expose
class S
{

};

class T : public ParentA::A
{

};

class U : public ParentA::B
{

};

class V : public ParentA::E
{

};

class X : public ParentA::F
{

};

/// \expose
class Y : public ParentA::E
{

};

class Z : public ParentA::E
{

};

}