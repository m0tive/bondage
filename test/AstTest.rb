require_relative 'TestUtils.rb'

require_relative "../parser/Library.rb"
require_relative "../parser/Parser.rb"
require_relative "../exposer/Exposer.rb"
require_relative "../exposer/ExposeAst.rb"

require 'test/unit'


class TestAst < Test::Unit::TestCase
  def setup
		@astTest = Library.new("AstTest", "test/testData/BasicAst")
		@astTest.addIncludePath(".")
		@astTest.addFile("BasicAst.h")
    
    setupLibrary(@astTest)
  end

  def teardown
		cleanLibrary(@astTest)
	end

  def test_ast
		parser = Parser.new(@astTest)

		visitor = ExposeAstVisitor.new(@astTest)
		parser.parse(visitor)

		assert_equal 1, visitor.classes.length
		cls = visitor.classes[0]
		assert_equal "::BasicAst::Foo", cls.fullyQualifiedName

		rootNs = visitor.rootItem
		assert_equal "", rootNs.name
		assert_equal 1, rootNs.namespaces.length
		ns = rootNs.namespaces.values[0]
		assert_not_nil ns
		assert_equal 0, ns.namespaces.length
		assert_equal 1, ns.classes.length

		assert_equal ns.classes.values[0], cls

		assert_equal 1, cls.functions.length
		fn = cls.functions[0]
		assert_equal "test", fn.name

		assert_equal true, cls.comment.hasCommand("expose")
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
end