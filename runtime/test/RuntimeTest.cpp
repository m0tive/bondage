#include <QString>
#include <QtTest>

#include "Generator/autogen_Gen/Gen.h"
#include "bondage/Library.h"
#include "bondage/Boxer.h"

class RuntimeTest : public QObject
  {
  Q_OBJECT

private Q_SLOTS:
  void testTypes();
  };

namespace Crate
{

template <typename Derived> class CastHelper<Gen::Gen, Derived>
  {
public:
  typedef Traits<Gen::Gen> RootTraits;

  static bool canCast(const Gen::Gen *root)
    {
    auto cast = dynamic_cast<const Derived*>(root);

    return cast != nullptr;
    }
  };

}

template <typename T> struct Helper
  {
  typedef Crate::Traits<T> Traits;

  static std::unique_ptr<bondage::Boxer::BoxedContainer> create(
      bondage::Boxer *boxer,
      T *data)
    {
    auto box = boxer->create<Traits>();
    Traits::box(boxer, box.get(), data);

    return box;
    }
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

  QVERIFY(4 == classes.size());

  QVERIFY(classes["Gen"]);
  QVERIFY(classes["InheritTest"]);
  QVERIFY(classes["MultipleReturnGen"]);
  QVERIFY(classes["CtorGen"]);


  bondage::Boxer boxer;

  // Multigen and ctor gen should only cast to themselves.
  auto multiGen = Helper<Gen::MultipleReturnGen>::create(&boxer, new Gen::MultipleReturnGen);
  QVERIFY(Crate::Traits<Gen::MultipleReturnGen>::canUnbox(&boxer, multiGen.get()));
  QVERIFY(!Crate::Traits<Gen::CtorGen>::canUnbox(&boxer, multiGen.get()));
  QVERIFY(!Crate::Traits<Gen::Gen>::canUnbox(&boxer, multiGen.get()));
  QVERIFY(!Crate::Traits<Gen::InheritTest>::canUnbox(&boxer, multiGen.get()));

  auto ctorGen = Helper<Gen::CtorGen>::create(&boxer, new Gen::CtorGen);
  QVERIFY(!Crate::Traits<Gen::MultipleReturnGen>::canUnbox(&boxer, ctorGen.get()));
  QVERIFY(Crate::Traits<Gen::CtorGen>::canUnbox(&boxer, ctorGen.get()));
  QVERIFY(!Crate::Traits<Gen::Gen>::canUnbox(&boxer, ctorGen.get()));
  QVERIFY(!Crate::Traits<Gen::InheritTest>::canUnbox(&boxer, ctorGen.get()));


  // genbox and inheritbox should cast to derived types.
  auto inheritBox = Helper<Gen::Gen>::create(&boxer, new Gen::InheritTest);
  auto inheritBox2 = Helper<Gen::InheritTest>::create(&boxer, new Gen::InheritTest);
  auto genBox = Helper<Gen::Gen>::create(&boxer, new Gen::Gen);

  // check no casting to other types
  QVERIFY(!Crate::Traits<Gen::MultipleReturnGen>::canUnbox(&boxer, inheritBox.get()));
  QVERIFY(!Crate::Traits<Gen::CtorGen>::canUnbox(&boxer, inheritBox.get()));
  QVERIFY(!Crate::Traits<Gen::MultipleReturnGen>::canUnbox(&boxer, genBox.get()));
  QVERIFY(!Crate::Traits<Gen::CtorGen>::canUnbox(&boxer, genBox.get()));

  // both object can be a gen.
  QVERIFY(Crate::Traits<Gen::Gen>::canUnbox(&boxer, genBox.get()));
  QVERIFY(Crate::Traits<Gen::Gen>::canUnbox(&boxer, inheritBox.get()));
  QVERIFY(Crate::Traits<Gen::Gen>::canUnbox(&boxer, inheritBox.get()));

  // only the derived type can be an inherittest
  QVERIFY(!Crate::Traits<Gen::InheritTest>::canUnbox(&boxer, genBox.get()));
  QVERIFY(Crate::Traits<Gen::InheritTest>::canUnbox(&boxer, inheritBox.get()));
  QVERIFY(Crate::Traits<Gen::InheritTest>::canUnbox(&boxer, inheritBox2.get()));

  QVERIFY(false);
  //test finding derived class type from box...?
  }

QTEST_APPLESS_MAIN(RuntimeTest)

#include "RuntimeTest.moc"
