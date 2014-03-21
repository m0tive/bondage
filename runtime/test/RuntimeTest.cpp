#include <QString>
#include <QtTest>

#include "Generator/autogen_Gen/Gen.h"

class RuntimeTest : public QObject
  {
  Q_OBJECT

private Q_SLOTS:
  void testTypes();
  };

void RuntimeTest::testTypes()
  {
  const Reflect::Type *value = Reflect::findType<Gen::Gen>();
  const Reflect::Type *ptr = Reflect::findType<Gen::Gen*>();
  const Reflect::Type *constPtr = Reflect::findType<const Gen::Gen*>();
  const Reflect::Type *ref = Reflect::findType<Gen::Gen&>();
  const Reflect::Type *constRef = Reflect::findType<const Gen::Gen&>();

  QCOMPARE(value, ptr);
  QCOMPARE(value, constPtr);
  QCOMPARE(value, ref);
  QCOMPARE(value, constRef);
  }

QTEST_APPLESS_MAIN(RuntimeTest)

#include "RuntimeTest.moc"
