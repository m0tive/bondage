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

		@parentB = Library.new("ParentB", "test/testData/ParentB")
		@parentB.addIncludePath(".")
		@parentB.addFile("ParentB.h")

    setupLibrary(@astTest)
    setupLibrary(@parentA)
    setupLibrary(@parentB)

  end

  def teardown
		cleanLibrary(@astTest)
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

  def test_parenting
  	# Generate parent A
		parser = Parser.new(@parentA)

		visitor = ExposeAstVisitor.new(@parentA)
		parser.parse(visitor)

		exposer = Exposer.new(visitor)

		assert_equal 2, exposer.exposedMetaData.fullClasses.length
		assert_equal 3, exposer.exposedMetaData.classes.length

		assert_equal "::ParentA::B", exposer.exposedMetaData.fullClasses.keys[0]
		assert_equal "::ParentA::B", exposer.exposedMetaData.classes.keys[0]
		assert_equal "::ParentA::E", exposer.exposedMetaData.classes.keys[1]
		assert_equal "::ParentA::F", exposer.exposedMetaData.fullClasses.keys[1]
		assert_equal "::ParentA::F", exposer.exposedMetaData.classes.keys[2]

		# Generate parent B
		parser = Parser.new(@parentB)

		visitor = ExposeAstVisitor.new(@parentB)
		parser.parse(visitor)

		exposer = Exposer.new(visitor)


	end

	# exposed classes
	# classes from parent libraries being skipped
	# super classes
	# - partial classes
	# exposed functions
	# exposed constructors
	# class copyability
	# pushing - push style?
	# diagnostic information? - clang_getDiagnostic - http://llvm.org/devmtg/2010-11/Gregor-libclang.pdf


end