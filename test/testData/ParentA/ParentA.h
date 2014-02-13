namespace ParentA
{

class A
{
};

/// \expose
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
class F : public E
{

};

}