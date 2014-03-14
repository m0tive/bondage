namespace VirtualFunctions
{

/// \expose derivable
class A
{
public:
  virtual void pork() = 0;
};

/// \expose
class B : public A
{
public:
  void pork() override;
};

}