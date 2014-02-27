namespace ParentA
{

class A
{
};

/// \expose 
/// \derivable
class B : public A
{
};

class C : public A
{
};

class D : protected B
{
};

class E : public B
{
};

/// \expose 
/// \derivable
class F : public E
{
};

/// \expose
class G
{
};

class H : public G
{
};

}