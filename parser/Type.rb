# Type wraps a parsed type from clang.
# Provided during argument/return type parsing.
class Type
  # create a type from the clang type.
  # it is not possible to create a type without a clang type.
  def initialize(type)
    @type = type
    @canonical = type.canonical
  end

  # strip any template brackets from the string [n].
  def self.stripTemplates(n)
    templateBrackets = 0
    endPoint = n.length
    (n.length-1).step(0, -1).each do |idx|
      isBracket = false
      if(n[idx] == ">")
        isBracket = true
        templateBrackets = templateBrackets + 1
      end

      if(n[idx] == "<")
        isBracket = true
        templateBrackets = templateBrackets - 1
      end

      if(templateBrackets == 0 && !isBracket)
        endPoint = idx + 1
        break
      end
    end

    return n[0, endPoint]
  end

  # find if the type is "void"
  def isVoid
    return @canonical.kind == :type_void
  end

  # find if the type is a bool
  def isBoolean
    return @canonical.kind == :type_bool
  end

  # find if the type is a const char* or a const wchar_t*
  def isStringLiteral
    if(!isPointer())
      return false
    end

    ptd = pointeeType()
    if(!ptd.isConstQualified())
      return false
    end

    return ptd.isCharacter()
  end

  def isCharacter
    return @canonical.kind == :type_schar ||
        @canonical.kind == :type_wchar ||
        @canonical.kind == :type_char_s
  end

  def isSignedInteger
    return @canonical.kind == :type_char_u ||
        @canonical.kind == :type_char16 ||
        @canonical.kind == :type_char32 ||
        @canonical.kind == :type_short ||
        @canonical.kind == :type_int ||
        @canonical.kind == :type_long ||
        @canonical.kind == :type_longlong ||
        @canonical.kind == :type_int128
  end

  def isUnsignedInteger
    return @canonical.kind == :type_uchar ||
        @canonical.kind == :type_ushort ||
        @canonical.kind == :type_uint ||
        @canonical.kind == :type_ulong ||
        @canonical.kind == :type_ulonglong ||
        @canonical.kind == :type_uint128
  end

  # find if the type is an integer.
  def isInteger
    return isCharacter() || isSignedInteger() || isUnsignedInteger()
  end

  # find if the type is a floating point type.
  def isFloatingPoint
    return @canonical.kind == :type_float ||
      @canonical.kind == :type_double ||
      @canonical.kind == :type_longdouble
  end

  # find a pretty string to represent the type
  def prettyName
    return "#{@type.spelling}"
  end

  # find if the type has a const qualification
  def isConstQualified
    return @canonical.const_qualified?
  end

  # find a short name, without decoration or templating for the type.
  def name
    n = @canonical.spelling
    if(isConstQualified)
      n.sub!("const ", "")
    end

    return Type.stripTemplates(n)
  end

  # find the clang :kind for the type.
  def kind
    return @canonical.kind
  end

  # find if the type is a pointer
  def isPointer
    return @canonical.kind == :type_pointer
  end

  # find if the type is an lvalue reference
  def isLValueReference
    return @canonical.kind == :type_lvalue_ref
  end

  # find if the type is an rvalue reference
  def isRValueReference
    return @canonical.kind == :type_rvalue_ref
  end

  # find the type the pointer or reference refers to.
  def pointeeType
    return Type.new(@canonical.pointee)
  end

  # find a string description for the type, for debugging
  def description
    return "#{@canonical.spelling} #{@canonical.kind}"
  end

  # find the result type for this type, if the type is a function signature.
  def resultType
    if(@type.result_type.kind == :type_void)
      return nil
    end

    return Type.new(@type.result_type)
  end
end