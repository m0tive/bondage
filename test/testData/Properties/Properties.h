namespace Properties
{

/// \expose
class PropertyClass
{
public:

  /// \brief Get the pork
  /// \property pork test test get
  float getPork() const;

  /// \brief Set the pork
  /// \property pork test test set
  void setPork(float f);

  /// \brief Set the pork again
  /// \overload
  void setPork(double d);

  // \brief 
  void foo();
  // \brief 
  int bar();
};

}