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

    setupLibrary(@enum)
    setupLibrary(@astTest)
    setupLibrary(@parentA)
    setupLibrary(@parentB)
  end

  def teardown
    #cleanLibrary(@enum)
    cleanLibrary(@astTest)
    cleanLibrary(@parentA)
    cleanLibrary(@parentB)
  end

  def test_metaData
    parser = Parser.new(@astTest)

    visitor = ExposeAstVisitor.new(@astTest)
    parser.parse(visitor)

    exposer = Exposer.new(visitor)

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
    parser = Parser.new(@astTest)

    visitor = ExposeAstVisitor.new(@astTest)
    parser.parse(visitor)

    exposer = Exposer.new(visitor)

  end

  def test_parentingA
    # Generate parent A
    exposer, visitor = expose(@parentA)

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
    expose(@parentA)
    # Generate parent B
    exposer, visitor = expose(@parentB)

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
    # Generate parent A
    exposer, visitor = expose(@enum)

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
  end

  def expose(lib)
    parser = Parser.new(lib)
    visitor = ExposeAstVisitor.new(lib)
    parser.parse(visitor)
    return Exposer.new(visitor), visitor
  end

  # super classes
  # - partial classes
  # static functions
  # exposed functions
  # exposed constructors
  # class copyability
  # pushing - push style?
  # diagnostic information? - clang_getDiagnostic - http://llvm.org/devmtg/2010-11/Gregor-libclang.pdf


end