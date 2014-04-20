
module Lua

  class NamedClassifier
    def processArgument(arg, type, mode, requiredClasses)
      requiredClass = type
      if (requiredClass.isPointer || requiredClass.isLValueReference)
        requiredClass = type.pointeeType
      end

      requiredClasses << requiredClass.fullyQualifiedName

      return "from_named(#{arg})"
    end
  end

end