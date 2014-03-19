#-------------------------------------------------
#
# Project created by QtCreator 2014-03-19T13:34:15
#
#-------------------------------------------------

QT       += testlib

QT       -= gui

TARGET = RuntimeTest
CONFIG   += console
CONFIG   -= app_bundle

TEMPLATE = app


SOURCES += RuntimeTest.cpp \
    ../../test/testData/GeneratorOutput/expected.cpp
DEFINES += SRCDIR=\\\"$$PWD/\\\"

HEADERS += \
    ../../test/testData/GeneratorOutput/expected.h \
    ../include/bondage/RuntimeHelpers.h \
    ../include/bondage/RuntimeHelpersImpl.h

INCLUDEPATH += \
  ../include/ \
  ../../test/testData/ \
  ../../test/testData/Generator
