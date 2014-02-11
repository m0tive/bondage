require_relative 'TestUtils.rb'

require_relative "../cobra_parser/Library.rb"
require_relative "../cobra_parser/Parser.rb"
require_relative "../cobra_exposer/ExposeAst.rb"
require_relative "../cobra_exposer/Exposer.rb"

require 'test/unit'


class TestPod < Test::Unit::TestCase
  def setup
		@podTest = Library.new("AstTest", "testData/BasicPodTypes")
		@podTest.addIncludePath(".")
		@podTest.addFile("BasicPodTypes.h")
  end

  def cleanup
		cleanLibrary(@podTest)  
	end

  def test_pod

		parser = Parser.new(@podTest)

		visitor = ExposeAstVisitor.new(@podTest)
		parser.parse(visitor)

		assert_equal 1, visitor.classes.length
		cls = visitor.classes[0]
		assert_not_nil cls


	end


  def cleanup
		cleanLibrary($podTest)  
	end

end