cd runtime/test

pushd
qmake

"%VS110COMNTOOLS%\VsDevCmd.bat"
"%VS110COMNTOOLS%\..\..\VC\bin\nmake" check

popd