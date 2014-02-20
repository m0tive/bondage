
# TypeExposer helps decide if a type can be exposed, given a set of types which are exposable.
#
# Not directly usable - use Exposer instead
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
      pointed = type.pointeeType()
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

    # otherwise, find the fully qualified type name, and find out if its exposed.
    fullName = type.fullyQualifiedName

    if((partialOk && @metaData.partiallyExposed?(fullName)) ||
      @metaData.fullyExposed?(fullName))
      return true
    end

    return false
  end
end