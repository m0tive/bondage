require_relative 'TestUtils.rb'

require_relative "../parser/Library.rb"
require_relative "../parser/Parser.rb"
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
end