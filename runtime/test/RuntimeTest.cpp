#include <QString>
#include <QtTest>

#include "Generator/autogen_Gen/Gen.h"
#include "bondage/Library.h"

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

  std::map<std::string, const bondage::WrappedClass *> classes;
  for(auto cls : bondage::ClassWalker(Gen::bindings()))
    {
    classes[cls->type().name()] = cls;
    }

  QVERIFY(classes["Gen"]);
  QVERIFY(classes["InheritTest"]);
  QVERIFY(classes["MultipleReturnGen"]);
  QVERIFY(classes["CtorGen"]);
  }

QTEST_APPLESS_MAIN(RuntimeTest)

#include "RuntimeTest.moc"
