namespace Named
{

/// \expose
class HelperThing
{
public:
  /// \expose
  enum TestTypes
  {
    TestA
  };

  /// \brief set the foo
  /// \property foo
  void setFoo(TestTypes a);

  /// \brief set the bar
  /// \property bar
  void setBar(float a);
};

/// \expose
class NamedClass
{
public:

  /// \brief do a pork
  /// \param data [named] The pork to do.
  void doAPork(HelperThing &data)
};


/// \expose 
/// \brief Extra pork function
/// \param t [named]
void doMorePork(HelperThing &t);

}