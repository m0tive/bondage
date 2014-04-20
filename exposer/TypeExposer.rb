
# TypeExposer helps decide if a type can be exposed, given a set of types which are exposable.
#
# Not directly usable - use ClassExposer instead
#
class TypeExposer
  def initialize(metaData)
    @metaData = metaData
  end

  # Find if [type], a Type class, can be exposed.
  def canExposeType(type, partialOk)
    # basic types can always be exposed
    if(type.isVoid() ||
       type.isBoolean() ||
       type.isStringLiteral() ||
       type.isInteger() ||
       type.isFloatingPoint())
      return true
    end

    # Pointer and reference types can be exposed if their pointed type can be exposed,
    # and they arent pointers to pointers.
    if(type.isPointer() || type.isLValueReference() || type.isRValueReference())
      return canExposePointerType(type.pointeeType(), partialOk)
    end

    return canExposeComplexType(type, partialOk)
  end

  def canExposePointerType(pointed, partialOk)
    if(pointed.isPointer())
      return false
    end

    if(pointed.isVoid() ||
       pointed.isBoolean() ||
       pointed.isCharacter() ||
       pointed.isInteger() ||
       pointed.isFloatingPoint())
      return false
    end

    return canExposeType(pointed, partialOk)
  end

  def canExposeComplexType(type, partialOk)
    # otherwise, find the fully qualified type name, and find out if its exposed.
    fullName = type.fullyQualifiedName

    foundClass = nil
    if (partialOk)
      foundClass = @metaData.types[fullName]
    elsif
      foundClass = @metaData.fullTypes[fullName]
    end

    if (!foundClass)
      return false
    end

    return canExposeTemplateArguments(foundClass, type, partialOk)
  end

  def canExposeTemplateArguments(templateMetaData, type, partialOk) 
    argsToSatisfy = templateMetaData.templateArgumentsToSatisfy
    if (!argsToSatisfy)
      return true;
    end

    argCount = type.templateArgCount

    argsToSatisfy.each do |i|
      raise "Invalid template type index" unless i < argCount

      arg = type.templateArg(i)
      if (!canExposeType(arg, partialOk))
        return false
      end
    end

    return true
  end
end