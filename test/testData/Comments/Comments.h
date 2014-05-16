namespace Comments
{

//--------------------------------------------------------------------
/// \expose 
/// \brief Extra pork function
/// \param t does the pork
//--------------------------------------------------------------------
void doMorePork(int t);
/// \expose
void doMorePork(short t);
void doMorePork(float t);

//////////////////////////////////////////////////////////////////////
/// \expose
/// \brief Extra Extra pork function
/// note that this is a longer brief.
/// \param t does the pork
//////////////////////////////////////////////////////////////////////
void doMorePork2(int t);

//////////////////////////////////////////////////////////////////////
/// \brief This is not exposed!
/// \param t does things
//////////////////////////////////////////////////////////////////////
void doMorePork3(int t);

}