#include <QString>
#include <QtTest>

#include "GeneratorOutput/expected.h"

class RuntimeTest : public QObject
  {
  Q_OBJECT

public:
  RuntimeTest();

private Q_SLOTS:
  void test1();
  };

RuntimeTest::RuntimeTest()
  {
  }

void RuntimeTest::test1()
  {
  QVERIFY2(true, "Failure");
  }

QTEST_APPLESS_MAIN(RuntimeTest)

#include "RuntimeTest.moc"
