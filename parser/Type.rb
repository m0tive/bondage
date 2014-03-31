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
  def self.findTemplateStart(n, start=nil)
    endPoint = start ? start : n.length

    (endPoint-1).step(0, -1).each do |idx|

      if(n[idx] != ">")
        next
      end

      thisSegmentStart = Type.findTemplateStart(n, idx) - 1

      thisSegmentStart.step(0, -1).each do |idx|

        if(n[idx] != "<")
          next
        end

        return idx
      end
    end
    return endPoint
  end

  def self.stripTemplates(n)
    return n[0, Type.findTemplateStart(n)]
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

  CHARACTER_TYPES = [ 
    :type_schar,
    :type_wchar, 
    :type_char_s 
  ]
  SIGNED_INTEGER_TYPES = [ 
    :type_char_u,
    :type_char16,
    :type_char32,
    :type_short,
    :type_int,
    :type_long,
    :type_longlong, 
    :type_int128
  ]
  UNSIGNED_INTEGER_TYPES = [ 
    :type_uchar,
    :type_ushort,
    :type_uint,
    :type_ulong,
    :type_ulonglong,
    :type_uint128
  ]

  def isCharacter
    return CHARACTER_TYPES.include?(@canonical.kind)
  end

  def isSignedInteger
    return SIGNED_INTEGER_TYPES.include?(@canonical.kind)
  end

  def isUnsignedInteger
    return UNSIGNED_INTEGER_TYPES.include?(@canonical.kind)
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

  # find a name, without decoration or templating for the type, but includeing namespacesss
  def name
    n = @canonical.spelling
    if(isConstQualified)
      n.sub!("const ", "")
    end

    return Type.stripTemplates(n)
  end

  # find a short name, without decoration or templating for the type.
  def shortName
    n = name
    idx = n.rindex("::")

    return n[(idx+2)..n.length]
  end

  def fullyQualifiedName
    return "::#{name}"
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

  # Find the number of template arguments
  def templateArgCount
    return @type.num_template_arguments
  end

  # Find the number of template arguments
  def templateArg(i)
    return Type.new(@type.template_argument(i))
  end
end