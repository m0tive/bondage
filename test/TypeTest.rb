require_relative 'TestUtils.rb'

require_relative "../parser/Library.rb"
require_relative "../parser/Parser.rb"
require_relative "../exposer/ParsedLibrary.rb"
require_relative "../exposer/Exposer.rb"

require 'test/unit'


class TestPod < Test::Unit::TestCase
  def setup
    @podTest = Library.new("AstTest", "test/testData/BasicPodTypes")
    @podTest.addIncludePath(".")
    @podTest.addFile("BasicPodTypes.h")
    
    setupLibrary(@podTest)
  end

  def teardown
    cleanLibrary(@podTest)  
  end

  def test_pod
    visitor = ParsedLibrary.parse(@podTest)

    assert_equal 1, visitor.classes.length
    cls = visitor.classes[0]
    assert_not_nil cls

    fns = cls.functions
    assert_equal 12, fns.length

    test1 = fns[0]
    assert_equal "test1", test1.name
    assert_nil test1.returnType

    test2 = fns[1]
    assert_equal "test2", test2.name
    assert_equal false, test2.returnType.isVoid
    assert_equal false, test2.returnType.isBoolean
    assert_equal false, test2.returnType.isStringLiteral
    assert_equal false, test2.returnType.isCharacter
    assert_equal true, test2.returnType.isSignedInteger
    assert_equal false, test2.returnType.isUnsignedInteger
    assert_equal true, test2.returnType.isInteger
    assert_equal false, test2.returnType.isFloatingPoint

    test3 = fns[2]
    assert_equal "test3", test3.name
    assert_equal false, test3.returnType.isVoid
    assert_equal false, test3.returnType.isBoolean
    assert_equal false, test3.returnType.isStringLiteral
    assert_equal false, test3.returnType.isCharacter
    assert_equal false, test3.returnType.isSignedInteger
    assert_equal true, test3.returnType.isUnsignedInteger
    assert_equal true, test3.returnType.isInteger
    assert_equal false, test3.returnType.isFloatingPoint

    test4 = fns[3]
    assert_equal "test4", test4.name
    assert_equal false, test4.returnType.isVoid
    assert_equal false, test4.returnType.isBoolean
    assert_equal false, test4.returnType.isStringLiteral
    assert_equal false, test4.returnType.isCharacter
    assert_equal false, test4.returnType.isSignedInteger
    assert_equal false, test4.returnType.isUnsignedInteger
    assert_equal false, test4.returnType.isInteger
    assert_equal true, test4.returnType.isFloatingPoint

    test5 = fns[4]
    assert_equal "test5", test5.name
    assert_equal false, test5.returnType.isVoid
    assert_equal true, test5.returnType.isBoolean
    assert_equal false, test5.returnType.isStringLiteral
    assert_equal false, test5.returnType.isCharacter
    assert_equal false, test5.returnType.isSignedInteger
    assert_equal false, test5.returnType.isUnsignedInteger
    assert_equal false, test5.returnType.isInteger
    assert_equal false, test5.returnType.isFloatingPoint


    test6 = fns[5]
    assert_equal "test6", test6.name
    assert_equal false, test6.returnType.isVoid
    assert_equal false, test6.returnType.isBoolean
    assert_equal false, test6.returnType.isStringLiteral
    assert_equal false, test6.returnType.isCharacter
    assert_equal false, test6.returnType.isSignedInteger
    assert_equal false, test6.returnType.isUnsignedInteger
    assert_equal false, test6.returnType.isInteger
    assert_equal false, test6.returnType.isFloatingPoint

    test7 = fns[6]
    assert_equal "test7", test7.name
    assert_equal false, test7.returnType.isVoid
    assert_equal false, test7.returnType.isBoolean
    assert_equal false, test7.returnType.isStringLiteral
    assert_equal false, test7.returnType.isCharacter
    assert_equal false, test7.returnType.isSignedInteger
    assert_equal false, test7.returnType.isUnsignedInteger
    assert_equal false, test7.returnType.isInteger
    assert_equal false, test7.returnType.isFloatingPoint

    test8 = fns[7]
    assert_equal "test8", test8.name
    assert_equal false, test8.returnType.isVoid
    assert_equal false, test8.returnType.isBoolean
    assert_equal false, test8.returnType.isStringLiteral
    assert_equal false, test8.returnType.isCharacter
    assert_equal false, test8.returnType.isSignedInteger
    assert_equal false, test8.returnType.isUnsignedInteger
    assert_equal false, test8.returnType.isInteger
    assert_equal false, test8.returnType.isFloatingPoint

    test9 = fns[8]
    assert_equal "test9", test9.name
    assert_equal false, test9.returnType.isVoid
    assert_equal false, test9.returnType.isBoolean
    assert_equal false, test9.returnType.isStringLiteral
    assert_equal false, test9.returnType.isCharacter
    assert_equal false, test9.returnType.isSignedInteger
    assert_equal false, test9.returnType.isUnsignedInteger
    assert_equal false, test9.returnType.isInteger
    assert_equal false, test9.returnType.isFloatingPoint

    test10 = fns[9]
    assert_equal "test10", test10.name
    assert_equal false, test10.returnType.isVoid
    assert_equal false, test10.returnType.isBoolean
    assert_equal true, test10.returnType.isStringLiteral
    assert_equal false, test10.returnType.isCharacter
    assert_equal false, test10.returnType.isSignedInteger
    assert_equal false, test10.returnType.isUnsignedInteger
    assert_equal false, test10.returnType.isInteger
    assert_equal false, test10.returnType.isFloatingPoint

    test11 = fns[10]
    assert_equal "test11", test11.name
    assert_equal false, test11.returnType.isVoid
    assert_equal false, test11.returnType.isBoolean
    assert_equal false, test11.returnType.isStringLiteral
    assert_equal true, test11.returnType.isCharacter
    assert_equal false, test11.returnType.isSignedInteger
    assert_equal false, test11.returnType.isUnsignedInteger
    assert_equal true, test11.returnType.isInteger
    assert_equal false, test11.returnType.isFloatingPoint

    test12 = fns[11]
    assert_equal "test12", test12.name
    assert_equal false, test12.returnType.isVoid
    assert_equal false, test12.returnType.isBoolean
    assert_equal false, test12.returnType.isStringLiteral
    assert_equal false, test12.returnType.isCharacter
    assert_equal false, test12.returnType.isSignedInteger
    assert_equal false, test12.returnType.isUnsignedInteger
    assert_equal false, test12.returnType.isInteger
    assert_equal false, test12.returnType.isFloatingPoint
    assert_equal true, test12.returnType.isRValueReference
    assert_equal false, test12.returnType.pointeeType.isVoid
    assert_equal false, test12.returnType.pointeeType.isBoolean
    assert_equal false, test12.returnType.pointeeType.isStringLiteral
    assert_equal false, test12.returnType.pointeeType.isCharacter
    assert_equal false, test12.returnType.pointeeType.isSignedInteger
    assert_equal false, test12.returnType.pointeeType.isUnsignedInteger
    assert_equal false, test12.returnType.pointeeType.isInteger
    assert_equal true, test12.returnType.pointeeType.isFloatingPoint
  end


  def cleanup
    cleanLibrary($podTest)  
  end

end