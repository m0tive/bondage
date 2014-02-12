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

  def test_exposer
		parser = Parser.new(@astTest)

		visitor = ExposeAstVisitor.new(@astTest)
		parser.parse(visitor)

		exposer = Exposer.new(visitor)

	end
end