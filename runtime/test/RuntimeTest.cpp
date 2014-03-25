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

  template <typename Box> static bool canCast(Box *ifc, typename Box::BoxedData data)
    {
    auto root = RootTraits::unbox(ifc, data);
    Q_ASSERT(root);
    return dynamic_cast<Derived*>(root);
    }
  };

}

template <typename T> struct Helper
  {
  typedef Crate::Traits<T> Traits;

  static std::unique_ptr<bondage::Boxer::BoxedContainer> create(bondage::Boxer *boxer)
    {
    auto box = boxer->create<Traits>();
    Traits::box(boxer, box.get(), new T);

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


  typedef Crate::Traits<Gen::Gen> GenTraits;
  typedef Crate::Traits<Gen::InheritTest> InheritTraits;

  bondage::Boxer boxer;

  auto inheritBox = Helper<Gen::InheritTest>::create(&boxer);
  auto genBox = Helper<Gen::Gen>::create(&boxer);

  QVERIFY(GenTraits::canUnbox(&boxer, genBox.get()));
  QVERIFY(GenTraits::canUnbox(&boxer, inheritBox.get()));

  QVERIFY(!InheritTraits::canUnbox(&boxer, genBox.get()));
  QVERIFY(InheritTraits::canUnbox(&boxer, inheritBox.get()));
  }

QTEST_APPLESS_MAIN(RuntimeTest)

#include "RuntimeTest.moc"
