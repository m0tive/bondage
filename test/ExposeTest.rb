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

    setupLibrary(@astTest)
    setupLibrary(@parentA)
    setupLibrary(@parentB)
  end

  def teardown
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

    loaded = ClassDataSet.import(@astTest.autogenPath)

    assert_equal 1, all.classes.length
    assert_equal 1, all.fullClasses.length
    assert_equal 1, exposed.classes.length
    assert_equal 1, exposed.fullClasses.length
    assert_equal 1, loaded.classes.length
    assert_equal 1, loaded.fullClasses.length

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
    exposer = expose(@parentA)

    assert_equal 2, exposer.exposedMetaData.fullClasses.length
    assert_equal 3, exposer.exposedMetaData.classes.length

    assert_equal "::ParentA::B", exposer.exposedMetaData.fullClasses.keys[0]
    assert_equal "::ParentA::B", exposer.exposedMetaData.classes.keys[0]
    assert_equal "::ParentA::E", exposer.exposedMetaData.classes.keys[1]
    assert_equal "::ParentA::F", exposer.exposedMetaData.fullClasses.keys[1]
    assert_equal "::ParentA::F", exposer.exposedMetaData.classes.keys[2]

    assert_equal nil, exposer.exposedMetaData.findClass("::ParentA::B").parentClass
    assert_equal "::ParentA::B", exposer.exposedMetaData.findClass("::ParentA::E").parentClass
    assert_equal "::ParentA::E", exposer.exposedMetaData.findClass("::ParentA::F").parentClass
  end

  def test_parentingB
    # Generate parent A
    expose(@parentA)
    # Generate parent B
    exposer = expose(@parentB)

    assert_equal 2, exposer.exposedMetaData.fullClasses.length
    assert_equal 6, exposer.exposedMetaData.classes.length

    assert_equal "::ParentB::R", exposer.exposedMetaData.classes.keys[0]
    assert_equal "::ParentB::S", exposer.exposedMetaData.fullClasses.keys[0]
    assert_equal "::ParentB::S", exposer.exposedMetaData.classes.keys[1]
    assert_equal "::ParentB::U", exposer.exposedMetaData.classes.keys[2]
    assert_equal "::ParentB::V", exposer.exposedMetaData.classes.keys[3]
    assert_equal "::ParentB::X", exposer.exposedMetaData.classes.keys[4]
    assert_equal "::ParentB::Y", exposer.exposedMetaData.fullClasses.keys[1]
    assert_equal "::ParentB::Y", exposer.exposedMetaData.classes.keys[5]

    assert_equal "::ParentB::Q", exposer.exposedMetaData.findClass("::ParentB::R").parentClass
    assert_equal nil, exposer.exposedMetaData.findClass("::ParentB::S").parentClass
    assert_equal "::ParentA::B", exposer.exposedMetaData.findClass("::ParentB::U").parentClass
    assert_equal "::ParentA::E", exposer.exposedMetaData.findClass("::ParentB::V").parentClass
    assert_equal "::ParentA::F", exposer.exposedMetaData.findClass("::ParentB::X").parentClass
    assert_equal "::ParentA::E", exposer.exposedMetaData.findClass("::ParentB::Y").parentClass

    assert_equal "::ParentA::B", exposer.allMetaData.fullClasses.keys[0]
    assert_equal "::ParentA::B", exposer.allMetaData.classes.keys[0]
    assert_equal "::ParentA::E", exposer.allMetaData.classes.keys[1]
    assert_equal "::ParentA::F", exposer.allMetaData.fullClasses.keys[1]
    assert_equal "::ParentA::F", exposer.allMetaData.classes.keys[2]
    assert_equal "::ParentB::Z", exposer.allMetaData.fullClasses.keys[2] # Manually exposed
    assert_equal "::ParentB::Z", exposer.allMetaData.classes.keys[3] # Manually exposed
    assert_equal "::ParentB::Q", exposer.allMetaData.fullClasses.keys[3] # Manually exposed
    assert_equal "::ParentB::Q", exposer.allMetaData.classes.keys[4] # Manually exposed
    assert_equal "::ParentB::R", exposer.allMetaData.classes.keys[5]
    assert_equal "::ParentB::S", exposer.allMetaData.fullClasses.keys[4]
    assert_equal "::ParentB::S", exposer.allMetaData.classes.keys[6]
    assert_equal "::ParentB::U", exposer.allMetaData.classes.keys[7]
    assert_equal "::ParentB::V", exposer.allMetaData.classes.keys[8]
    assert_equal "::ParentB::X", exposer.allMetaData.classes.keys[9]
    assert_equal "::ParentB::Y", exposer.allMetaData.fullClasses.keys[5]
    assert_equal "::ParentB::Y", exposer.allMetaData.classes.keys[10]


  end

  def expose(lib)
    parser = Parser.new(lib)
    visitor = ExposeAstVisitor.new(lib)
    parser.parse(visitor)
    return Exposer.new(visitor)
  end

  # super classes
  # - partial classes
  # exposed functions
  # exposed constructors
  # class copyability
  # pushing - push style?
  # diagnostic information? - clang_getDiagnostic - http://llvm.org/devmtg/2010-11/Gregor-libclang.pdf


end