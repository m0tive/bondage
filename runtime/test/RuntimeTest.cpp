#include <QString>
#include <QtTest>

#include "Generator/autogen_Gen/Gen.h"
#include "bondage/Library.h"
#include "CastHelper.Gen_Gen.h"

#include "StringLibrary/StringLibrary.h"
#include "StringLibrary/autogen_String/String.h"

class RuntimeTest : public QObject
  {
  Q_OBJECT

private Q_SLOTS:
  void testTypeExistance();
  void testTypeCasting();
  void testFunctionExistance();
  void testStringLibrary();
  };

template <typename T> struct Helper
  {
  typedef Crate::Traits<T> Traits;

  static std::unique_ptr<Reflect::example::Object> create(
      bondage::Builder::Boxer *boxer,
      T *data)
    {
    auto box = boxer->create<Traits>();
    Traits::box(boxer, box.get(), data);

    return box;
    }
  };

void RuntimeTest::testTypeExistance()
  {
  const Crate::Type *value = Crate::findType<Gen::Gen>();
  const Crate::Type *ptr = Crate::findType<Gen::Gen*>();
  const Crate::Type *constPtr = Crate::findType<const Gen::Gen*>();
  const Crate::Type *ref = Crate::findType<Gen::Gen&>();
  const Crate::Type *constRef = Crate::findType<const Gen::Gen&>();

  QCOMPARE(value, ptr);
  QCOMPARE(value, constPtr);
  QCOMPARE(value, ref);
  QCOMPARE(value, constRef);

  std::map<std::string, const bondage::WrappedClass *> classes;
  for(auto cls : bondage::ClassWalker(Gen::bindings()))
    {
    classes[cls->type().name()] = cls;
    }

  QVERIFY(5 == classes.size());

  QVERIFY(classes["Gen"]);
  QVERIFY(classes["InheritTest"]);
  QVERIFY(classes["InheritTest2"]);
  QVERIFY(classes["MultipleReturnGen"]);
  QVERIFY(classes["CtorGen"]);
  }

void RuntimeTest::testTypeCasting()
  {
  std::map<std::string, const bondage::WrappedClass *> classes;
  for(auto cls : bondage::ClassWalker(Gen::bindings()))
    {
    classes[cls->type().name()] = cls;
    }

  bondage::Builder::Boxer boxer;

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
  auto inheritBox3 = Helper<Gen::Gen>::create(&boxer, new Gen::InheritTest2);
  auto genBox = Helper<Gen::Gen>::create(&boxer, new Gen::Gen);

  // check no casting to other types
  QVERIFY(!Crate::Traits<Gen::MultipleReturnGen>::canUnbox(&boxer, inheritBox.get()));
  QVERIFY(!Crate::Traits<Gen::CtorGen>::canUnbox(&boxer, inheritBox.get()));
  QVERIFY(!Crate::Traits<Gen::MultipleReturnGen>::canUnbox(&boxer, genBox.get()));
  QVERIFY(!Crate::Traits<Gen::CtorGen>::canUnbox(&boxer, genBox.get()));

  // both object can be a gen.
  QVERIFY(Crate::Traits<Gen::Gen>::canUnbox(&boxer, genBox.get()));
  QVERIFY(Crate::Traits<Gen::Gen>::canUnbox(&boxer, inheritBox.get()));
  QVERIFY(Crate::Traits<Gen::Gen>::canUnbox(&boxer, inheritBox2.get()));
  QVERIFY(Crate::Traits<Gen::Gen>::canUnbox(&boxer, inheritBox3.get()));

  // only the derived type can be an inherittest
  QVERIFY(!Crate::Traits<Gen::InheritTest>::canUnbox(&boxer, genBox.get()));
  QVERIFY(Crate::Traits<Gen::InheritTest>::canUnbox(&boxer, inheritBox.get()));
  QVERIFY(Crate::Traits<Gen::InheritTest>::canUnbox(&boxer, inheritBox2.get()));
  QVERIFY(Crate::Traits<Gen::InheritTest>::canUnbox(&boxer, inheritBox3.get()));

  // only the derived type can be an inherittest
  QVERIFY(!Crate::Traits<Gen::InheritTest2>::canUnbox(&boxer, genBox.get()));
  QVERIFY(!Crate::Traits<Gen::InheritTest2>::canUnbox(&boxer, inheritBox.get()));
  QVERIFY(!Crate::Traits<Gen::InheritTest2>::canUnbox(&boxer, inheritBox2.get()));
  QVERIFY(Crate::Traits<Gen::InheritTest2>::canUnbox(&boxer, inheritBox3.get()));

  auto multiGenData = Crate::Traits<Gen::MultipleReturnGen>::unbox(&boxer, multiGen.get());
  auto ctorGenData = Crate::Traits<Gen::CtorGen>::unbox(&boxer, ctorGen.get());
  auto genData = Crate::Traits<Gen::Gen>::unbox(&boxer, genBox.get());
  auto inherit1Data = Crate::Traits<Gen::Gen>::unbox(&boxer, inheritBox.get());
  auto inherit2Data = Crate::Traits<Gen::Gen>::unbox(&boxer, inheritBox2.get());
  auto inherit3Data = Crate::Traits<Gen::Gen>::unbox(&boxer, inheritBox3.get());

  auto ctorCls = bondage::WrappedClassFinder<Gen::CtorGen>::find(ctorGenData);
  auto ctorClsBase = bondage::WrappedClassFinder<Gen::CtorGen>::findBase();
  QCOMPARE(ctorCls, ctorClsBase);
  QCOMPARE(classes["CtorGen"], ctorCls);

  auto multiCls = bondage::WrappedClassFinder<Gen::MultipleReturnGen>::find(multiGenData);
  auto multiClsBase = bondage::WrappedClassFinder<Gen::MultipleReturnGen>::findBase();
  QCOMPARE(multiCls, multiClsBase);
  QCOMPARE(classes["MultipleReturnGen"], multiCls);

  auto genCls = bondage::WrappedClassFinder<Gen::Gen>::find(genData);
  auto genClsBase = bondage::WrappedClassFinder<Gen::Gen>::findBase();
  QCOMPARE(genCls, genClsBase);
  QCOMPARE(classes["Gen"], genCls);

  auto i1Cls = bondage::WrappedClassFinder<Gen::InheritTest>::find(inherit1Data);
  auto i1ClsBase = bondage::WrappedClassFinder<Gen::InheritTest>::findBase();
  QCOMPARE(i1Cls, i1ClsBase);
  QCOMPARE(classes["InheritTest"], i1Cls);

  auto i2Cls = bondage::WrappedClassFinder<Gen::Gen>::find(inherit2Data);
  auto i2ClsBase = bondage::WrappedClassFinder<Gen::Gen>::findBase();
  QCOMPARE(i2ClsBase, genCls);
  QCOMPARE(classes["InheritTest"], i2Cls);

  auto i3Cls = bondage::WrappedClassFinder<Gen::InheritTest2>::find(inherit3Data);
  auto i3ClsBase = bondage::WrappedClassFinder<Gen::InheritTest2>::findBase();
  QCOMPARE(i3Cls, i3ClsBase);
  QCOMPARE(classes["InheritTest2"], i3Cls);
  }

void RuntimeTest::testFunctionExistance()
  {
  std::map<std::string, const bondage::WrappedClass *> classes;
  for(auto cls : bondage::ClassWalker(Gen::bindings()))
    {
    classes[cls->type().name()] = cls;
    }

  auto ctorGen = classes["CtorGen"];
  QVERIFY(ctorGen->functionCount() == 1);
  QVERIFY("CtorGen" == ctorGen->function(0).name());

  auto multiGen = classes["MultipleReturnGen"];
  QVERIFY(multiGen->functionCount() == 1);
  QVERIFY("test" == multiGen->function(0).name());

  auto gen = classes["Gen"];
  QVERIFY(gen->functionCount() == 3);
  QVERIFY("test1" == gen->function(0).name());
  QVERIFY("test2" == gen->function(1).name());
  QVERIFY("test3" == gen->function(2).name());

  auto inheritGen = classes["InheritTest"];
  QVERIFY(inheritGen->functionCount() == 2);
  QVERIFY("pork" == inheritGen->function(0).name());
  QVERIFY("pork2" == inheritGen->function(1).name());

  auto inherit2Gen = classes["InheritTest2"];
  QVERIFY(inherit2Gen->functionCount() == 0);
  }

template <std::size_t ArgCount> struct Args
  {
public:
  Reflect::example::Object argumentStorage[ArgCount];
  Reflect::example::Object *argumentStoragePtrs[ArgCount];

  bondage::Builder::Arguments args;
  bondage::Builder::Boxer *boxer;

  void call(const bondage::Function *f)
    {
    f->call(boxer, &args);
    }
  };


template <> struct Args<0>
  {
public:
  bondage::Builder::Arguments args;
  bondage::Builder::Boxer *boxer;

  void call(const bondage::Function *f)
    {
    f->call(boxer, &args);
    }
  };

void createArgs(
    bondage::Builder::Boxer *boxer,
    Args<0> &out,
    Reflect::example::Object *obj)
  {
  out.boxer = boxer;
  out.args.ths = obj;
  }

template <typename A> void createArgs(
    bondage::Builder::Boxer *boxer,
    Args<1> &out,
    Reflect::example::Object *obj,
    A a)
  {
  Reflect::example::initArgs(boxer, out.argumentStorage, out.argumentStoragePtrs, a);
  out.boxer = boxer;
  out.args.args = out.argumentStoragePtrs;
  out.args.argCount = 1;
  out.args.ths = obj;
  }

template <typename A, typename B> void createArgs(
    bondage::Builder::Boxer *boxer,
    Args<2> &out,
    Reflect::example::Object *obj,
    A a,
    B b)
  {
  Reflect::example::initArgs(boxer, out.argumentStorage, out.argumentStoragePtrs, a, b);
  out.boxer = boxer;
  out.args.args = out.argumentStoragePtrs;
  out.args.argCount = 2;
  out.args.ths = obj;
  }

void RuntimeTest::testStringLibrary()
  {
  std::map<std::string, const bondage::WrappedClass *> classes;
  for(auto cls : bondage::ClassWalker(String::bindings()))
    {
    classes[cls->type().name()] = cls;
    }

  QVERIFY(1 == String::bindings().functionCount());
  auto quote = String::bindings().function(0);

  auto stringClass = classes["String"];
  QVERIFY(stringClass);


  std::map<std::string, const bondage::Function *> functions;
  for (std::size_t i = 0; i < stringClass->functionCount(); ++i)
    {
    functions[stringClass->function(i).name()] = &stringClass->function(i);
    }
  QVERIFY(functions["create"]);
  QVERIFY(functions["toUpper"]);

  bondage::Builder::Boxer boxer;

  Args<1> createStringArgs;
  createArgs(&boxer, createStringArgs, nullptr, "pork");
  createStringArgs.call(functions["create"]);


  QVERIFY(1 == createStringArgs.args.resultCount);
  QVERIFY(Reflect::example::Caster<String::String*>::canCast(&boxer, &createStringArgs.args.results[0]));
  QVERIFY(Reflect::example::Caster<String::String*>::cast(&boxer, &createStringArgs.args.results[0]) != nullptr);


  Args<0> toUpperArgs;
  createArgs(&boxer, toUpperArgs, &createStringArgs.args.results[0]);
  toUpperArgs.call(functions["toUpper"]);
  QVERIFY(Reflect::example::Caster<String::String*>::canCast(&boxer, &toUpperArgs.args.results[0]));
  String::String* upper = Reflect::example::Caster<String::String*>::cast(&boxer, &toUpperArgs.args.results[0]);
  QVERIFY(upper != nullptr);
  QCOMPARE(upper->val.c_str(), "PORK");


  Args<1> appendIntArgs;
  createArgs(&boxer, appendIntArgs, &toUpperArgs.args.results[0], 5);
  appendIntArgs.call(functions["append"]);

  QCOMPARE(upper->val.c_str(), "PORK5");

  Args<1> appendStringArgs;
  createArgs(&boxer, appendStringArgs, &toUpperArgs.args.results[0], "_TEST");
  appendStringArgs.call(functions["append"]);

  QCOMPARE(upper->val.c_str(), "PORK5_TEST");

  Args<2> appendIntIntArgs;
  createArgs(&boxer, appendIntIntArgs, &toUpperArgs.args.results[0], 1, 2);
  appendIntIntArgs.call(functions["append"]);

  QCOMPARE(upper->val.c_str(), "PORK5_TEST12");

  Args<1> quoteStringArgs;
  createArgs(&boxer, quoteStringArgs, nullptr, upper);
  quoteStringArgs.call(&quote);

  String::String* arg1 = Reflect::example::Caster<String::String*>::cast(&boxer, quoteStringArgs.args.args[0]);
  QCOMPARE(arg1->val.c_str(), "`PORK5_TEST12`");
  }

QTEST_APPLESS_MAIN(RuntimeTest)

#include "RuntimeTest.moc"
