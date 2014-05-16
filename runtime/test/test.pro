#-------------------------------------------------
#
# Project created by QtCreator 2014-03-19T13:34:15
#
#-------------------------------------------------

QT       += testlib

QT       -= gui

TARGET = RuntimeTest
CONFIG   += console testcase
CONFIG   -= app_bundle

TEMPLATE = app

win32-msvc2012 {
  # needs enabling for msvc2013, which has no mkspec yet...
  # QMAKE_CXXFLAGS += /FS
  DEFINES += REFLECT_MACRO_IMPL
}

SOURCES += \
  RuntimeTest.cpp \
  ../../test/testData/Generator/autogen_Gen/Gen.cpp \
    ../src/Library.cpp \
    ../src/WrappedClass.cpp \
    ../src/CastHelper.cpp \
    ../../test/testData/StringLibrary/autogen_String/String.cpp

DEFINES += SRCDIR=\\\"$$PWD/\\\"

HEADERS += \
    ../../test/testData/Generator/autogen_Gen/Gen.h \
    ../include/bondage/RuntimeHelpers.h \
    ../include/bondage/RuntimeHelpersImpl.h \
    ../include/bondage/Function.h \
    ../include/bondage/FunctionBuilder.h \
    ../include/bondage/Library.h \
    ../include/bondage/WrappedClass.h \
    ../include/bondage/Bondage.h \
    ../include/bondage/CastHelper.h \
    PackHelper.h \
    CastHelper.Gen_GenCls.h

INCLUDEPATH += \
  ../include/ \
  ../Reflect/include/ \
  ../../test/testData/ \
  ../../test/testData/Generator \
  ../../test/testData/StringLibrary \
  .

macx-clang {
  QMAKE_MACOSX_DEPLOYMENT_TARGET = 10.9
  QMAKE_CXXFLAGS += -std=c++11 -stdlib=libc++
}

linux-clang {
  QMAKE_CXXFLAGS += -std=c++11 -stdlib=libc++
  INCLUDEPATH += /usr/include/c++/4.6/ /usr/include/c++/4.6/x86_64-linux-gnu/32/
}

linux-g++ {
  QMAKE_CXXFLAGS += -std=c++0x
}

linux-g++-64 {
  QMAKE_CXXFLAGS += -std=c++0x
}
