namespace Constructors
{

/// \expose
class Ctor
{
public:
  Ctor();
  Ctor(int a);
  Ctor(float);
  Ctor(double a, double b);
  Ctor(const Ctor &);
  Ctor(Ctor &);
};

}