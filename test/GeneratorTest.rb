require_relative 'TestUtils.rb'

require_relative "../parser/Library.rb"
require_relative "../parser/Parser.rb"
require_relative "../exposer/ExposeAst.rb"
require_relative "../generators/Generator.rb"

require 'test/unit'


class TestGenerator < Test::Unit::TestCase
  def setup
    @gen = Library.new("Generator", "test/testData/Generator")
    @gen.addIncludePath(".")
    @gen.addFile("Generator.h")
    
    setupLibrary(@gen)
  end

  def teardown
    cleanLibrary(@gen)
  end

  def test_functionGenerator
    parser = Parser.new(@gen)

    visitor = ExposeAstVisitor.new(@gen)
    parser.parse(visitor)
  end
end