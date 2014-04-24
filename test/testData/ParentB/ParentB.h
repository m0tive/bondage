#include "ParentA.h"

namespace ParentB
{

class R;

/// \expose derivable
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

// Z is exposed manually somewhere else...
class Z : public ParentA::E
{
};

/// \noexpose
class Invisible1 : public ParentA::E
{
};

/// \noexpose
class Invisible2 : public S
{
};

}