
module Lua

  class IndexClassifier
    def processArgument(arg, type, mode, requiredClasses)

      baseType = type
      if (type.isPointer || type.isLValueReference)
        baseType = type.pointeeType
      end

      if (mode == :return)
        if (baseType.isInteger)
          return "(#{arg}-1)"
        else
          return "from_native(#{arg})"
        end
      end

      if (mode == :param)
        if (baseType.isInteger)
          return "(#{arg}-1)"
        else
          return "to_native(#{arg})"
        end
      end

      return arg
    end
  end

end