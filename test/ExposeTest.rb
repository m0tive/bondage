require_relative 'TestUtils.rb'

require_relative "../parser/Library.rb"
require_relative "../parser/Parser.rb"
require_relative "../exposer/Exposer.rb"
require_relative "../exposer/ExposeAst.rb"

require 'test/unit'


class TestExpose < Test::Unit::TestCase
  def setup
    @astTest = Library.new("AstTest", "test/testData/BasicAst")
    @astTest.addIncludePath(".")
    @astTest.addFile("BasicAst.h")

    @parentA = Library.new("ParentA", "test/testData/ParentA")
    @parentA.addIncludePath(".")
    @parentA.addFile("ParentA.h")

    @parentBManual = Library.new("ParentBManual", "test/testData/ParentB/ParentBManual")

    @parentB = Library.new("ParentB", "test/testData/ParentB")
    @parentB.addIncludePath(".")
    @parentB.addFile("ParentB.h")
    @parentB.addDependency(@parentA)
    @parentB.addDependency(@parentBManual)

    @enum = Library.new("Enum", "test/testData/Enum")
    @enum.addIncludePath(".")
    @enum.addFile("Enum.h")

    @functions = Library.new("Functions", "test/testData/Functions")
    @functions.addIncludePath(".")
    @functions.addFile("Functions.h")

    setupLibrary(@functions)
    setupLibrary(@enum)
    setupLibrary(@astTest)
    setupLibrary(@parentA)
    setupLibrary(@parentB)
  end

  def teardown
    #cleanLibrary(@functions)
    cleanLibrary(@enum)
    cleanLibrary(@astTest)
    cleanLibrary(@parentA)
    cleanLibrary(@parentB)
  end

  def test_metaData
    exposer, visitor = exposeLibrary(@astTest)

    all = exposer.allMetaData
    exposed = exposer.exposedMetaData

    loaded = TypeDataSet.import(@astTest.autogenPath)

    assert_equal 1, all.types.length
    assert_equal 1, all.fullTypes.length
    assert_equal 1, exposed.types.length
    assert_equal 1, exposed.fullTypes.length
    assert_equal 1, loaded.types.length
    assert_equal 1, loaded.fullTypes.length

    assert_equal true, all.fullyExposed?("::BasicAst::Foo")
    assert_equal true, all.partiallyExposed?("::BasicAst::Foo")
    assert_equal true, exposed.fullyExposed?("::BasicAst::Foo")
    assert_equal true, exposed.partiallyExposed?("::BasicAst::Foo")
    assert_equal true, loaded.fullyExposed?("::BasicAst::Foo")
    assert_equal true, loaded.partiallyExposed?("::BasicAst::Foo")
  end

  def test_exposer
    exposeLibrary(@astTest)
  end

  def test_parentingA
    # Generate parent A
    exposer, visitor = exposeLibrary(@parentA)

    assert_equal 2, exposer.exposedMetaData.fullTypes.length
    assert_equal 3, exposer.exposedMetaData.types.length

    assert_equal "::ParentA::B", exposer.exposedMetaData.fullTypes.keys[0]
    assert_equal "::ParentA::B", exposer.exposedMetaData.types.keys[0]
    assert_equal "::ParentA::E", exposer.exposedMetaData.types.keys[1]
    assert_equal "::ParentA::F", exposer.exposedMetaData.fullTypes.keys[1]
    assert_equal "::ParentA::F", exposer.exposedMetaData.types.keys[2]

    assert_equal nil, exposer.exposedMetaData.findClass("::ParentA::B").parentClass
    assert_equal "::ParentA::B", exposer.exposedMetaData.findClass("::ParentA::E").parentClass
    assert_equal "::ParentA::E", exposer.exposedMetaData.findClass("::ParentA::F").parentClass
  end

  def test_parentingB
    # Generate parent A
    exposeLibrary(@parentA)
    # Generate parent B
    exposer, visitor = exposeLibrary(@parentB)

    assert_equal 2, exposer.exposedMetaData.fullTypes.length
    assert_equal 6, exposer.exposedMetaData.types.length

    assert_equal "::ParentB::R", exposer.exposedMetaData.types.keys[0]
    assert_equal "::ParentB::S", exposer.exposedMetaData.fullTypes.keys[0]
    assert_equal "::ParentB::S", exposer.exposedMetaData.types.keys[1]
    assert_equal "::ParentB::U", exposer.exposedMetaData.types.keys[2]
    assert_equal "::ParentB::V", exposer.exposedMetaData.types.keys[3]
    assert_equal "::ParentB::X", exposer.exposedMetaData.types.keys[4]
    assert_equal "::ParentB::Y", exposer.exposedMetaData.fullTypes.keys[1]
    assert_equal "::ParentB::Y", exposer.exposedMetaData.types.keys[5]

    assert_equal "::ParentB::Q", exposer.exposedMetaData.findClass("::ParentB::R").parentClass
    assert_equal nil, exposer.exposedMetaData.findClass("::ParentB::S").parentClass
    assert_equal "::ParentA::B", exposer.exposedMetaData.findClass("::ParentB::U").parentClass
    assert_equal "::ParentA::E", exposer.exposedMetaData.findClass("::ParentB::V").parentClass
    assert_equal "::ParentA::F", exposer.exposedMetaData.findClass("::ParentB::X").parentClass
    assert_equal "::ParentA::E", exposer.exposedMetaData.findClass("::ParentB::Y").parentClass

    assert_equal "::ParentA::B", exposer.allMetaData.fullTypes.keys[0]
    assert_equal "::ParentA::B", exposer.allMetaData.types.keys[0]
    assert_equal "::ParentA::E", exposer.allMetaData.types.keys[1]
    assert_equal "::ParentA::F", exposer.allMetaData.fullTypes.keys[1]
    assert_equal "::ParentA::F", exposer.allMetaData.types.keys[2]
    assert_equal "::ParentB::Z", exposer.allMetaData.fullTypes.keys[2] # Manually exposed
    assert_equal "::ParentB::Z", exposer.allMetaData.types.keys[3] # Manually exposed
    assert_equal "::ParentB::Q", exposer.allMetaData.fullTypes.keys[3] # Manually exposed
    assert_equal "::ParentB::Q", exposer.allMetaData.types.keys[4] # Manually exposed
    assert_equal "::ParentB::R", exposer.allMetaData.types.keys[5]
    assert_equal "::ParentB::S", exposer.allMetaData.fullTypes.keys[4]
    assert_equal "::ParentB::S", exposer.allMetaData.types.keys[6]
    assert_equal "::ParentB::U", exposer.allMetaData.types.keys[7]
    assert_equal "::ParentB::V", exposer.allMetaData.types.keys[8]
    assert_equal "::ParentB::X", exposer.allMetaData.types.keys[9]
    assert_equal "::ParentB::Y", exposer.allMetaData.fullTypes.keys[5]
    assert_equal "::ParentB::Y", exposer.allMetaData.types.keys[10]


  end

  def test_enum
    # Generate Enum
    exposer, visitor = exposeLibrary(@enum)

    assert_equal 3, exposer.allMetaData.fullTypes.length
    assert_equal 3, exposer.exposedMetaData.fullTypes.length
    assert_equal 3, exposer.allMetaData.types.length
    assert_equal 3, exposer.exposedMetaData.types.length

    assert_equal "::Enum::ExposedClass", exposer.allMetaData.fullTypes.keys[0]
    assert_equal "::Enum::ExposedClass::ExposedEnum", exposer.allMetaData.fullTypes.keys[1]
    assert_equal "::Enum::ExposedEnumStatic", exposer.allMetaData.fullTypes.keys[2]

    nsEnum = exposer.allMetaData.fullTypes["::Enum::ExposedEnumStatic"].parsed
    assert_not_nil nsEnum

    assert_equal 3, nsEnum.members.length
    assert_equal 5, nsEnum.members["A"]
    assert_equal 10, nsEnum.members["B"]
    assert_equal 1, nsEnum.members["C"]

    classEnum = exposer.allMetaData.fullTypes["::Enum::ExposedClass::ExposedEnum"].parsed
    assert_not_nil classEnum

    assert_equal 3, classEnum.members.length
    assert_equal 0, classEnum.members["X"]
    assert_equal 1, classEnum.members["Y"]
    assert_equal 2, classEnum.members["Z"]

    cls = exposer.allMetaData.fullTypes["::Enum::ExposedClass"].parsed
    functions = exposer.findExposedFunctions(cls)
    assert_equal 2, functions.length

    fns1 = functions["fn1"]
    fns2 = functions["fn3"]

    assert_not_nil fns1
    assert_not_nil fns2

    fn1 = fns1[0]
    fn2 = fns2[0]

    assert_not_nil fn1
    assert_not_nil fn2

    assert_equal nil, fn1.returnType
    assert_equal nil, fn2.returnType

    assert_equal 1, fn1.arguments.length
    assert_equal 1, fn2.arguments.length

    assert_equal "::Enum::ExposedEnumStatic", fn1.arguments[0].type.fullyQualifiedName
    assert_equal "::Enum::ExposedClass::ExposedEnum", fn2.arguments[0].type.fullyQualifiedName
  end

  def test_functions
    # Generate Functions
    exposer, visitor = exposeLibrary(@functions)

    rootNs = visitor.getExposedNamespace()
    assert_not_nil rootNs

    assert_equal 3, rootNs.functions.length

    fns = exposer.findExposedFunctions(rootNs)
    assert_equal 2, fns.length

    expose1 = fns["testExpose1"]
    assert_equal 1, expose1.length
    assert_equal true, expose1[0].returnType.isLValueReference
    assert_equal true, expose1[0].returnType.pointeeType.isConstQualified
    assert_equal "::Functions::TestA", expose1[0].returnType.pointeeType.fullyQualifiedName

    assert_equal 2, expose1[0].arguments.length
    assert_equal "", expose1[0].arguments[0].name
    assert_equal true, expose1[0].arguments[0].type.isFloatingPoint()
    assert_equal "pork", expose1[0].arguments[1].name
    assert_equal true, expose1[0].arguments[1].type.isBoolean()

    assert_equal true, expose1[0].returnType.isLValueReference
    assert_equal true, expose1[0].returnType.pointeeType.isConstQualified
    assert_equal "::Functions::TestA", expose1[0].returnType.pointeeType.fullyQualifiedName

    expose2 = fns["testExpose2"]
    assert_equal 1, expose2.length

    expose2_1 = expose2[0]
    assert_equal true, expose2_1.returnType.isLValueReference
    assert_equal false, expose2_1.returnType.pointeeType.isConstQualified
    assert_equal "::Functions::TestA", expose1[0].returnType.pointeeType.fullyQualifiedName

    assert_equal 1, expose2_1.arguments.length
    assert_equal "a", expose2_1.arguments[0].name
    assert_equal true, expose2_1.arguments[0].type.isPointer()
    assert_equal "::Functions::TestA", expose2_1.arguments[0].type.pointeeType().fullyQualifiedName

    assert_equal 2, exposer.exposedMetaData.fullTypes.length

    exposeHelper = exposer.exposedMetaData.fullTypes["::Functions::TestA"].parsed
    assert_not_nil exposeHelper

    exposedClass = exposer.exposedMetaData.fullTypes["::Functions::SomeClass"].parsed
    assert_not_nil exposedClass

    assert_equal 4, exposedClass.functions.length

    fns = exposer.findExposedFunctions(exposedClass)
    assert_equal 1, fns.length

    overloaded = fns["overloaded"]
    assert_equal 3, overloaded.length

    overloaded.each do |fn|
      assert_equal nil, fn.returnType
    end

    assert_equal 1, overloaded[0].arguments.length
    assert_equal 3, overloaded[1].arguments.length
    assert_equal 1, overloaded[2].arguments.length

    assert_equal false, overloaded[0].static
    assert_equal true, overloaded[0].arguments[0].type.isLValueReference
    assert_equal "::Functions::TestA", overloaded[0].arguments[0].type.pointeeType.fullyQualifiedName
    
    assert_equal false, overloaded[1].static
    assert_equal true, overloaded[1].arguments[0].type.isLValueReference
    assert_equal "::Functions::TestA", overloaded[0].arguments[0].type.pointeeType.fullyQualifiedName
    assert_equal true, overloaded[1].arguments[1].type.isSignedInteger
    assert_equal true, overloaded[1].arguments[2].type.isFloatingPoint
    
    assert_equal true, overloaded[2].static
    assert_equal true, overloaded[2].arguments[0].type.isPointer
    assert_equal "::Functions::TestA", overloaded[2].arguments[0].type.pointeeType.fullyQualifiedName
  end

  # super classes
  # - partial classes
  # static functions
  # exposed constructors
  # class copyability
  # pushing - push style?
  # indexes in methods
  # default values in arguments (changing exposureness?)
  

end