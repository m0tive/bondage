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

    setupLibrary(@astTest)
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