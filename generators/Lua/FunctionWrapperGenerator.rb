
module Lua

  class FunctionWrapperGenerator
    class ArgumentOverload
      def initialize()
        @returnTypes = []
        @arguments = []
      end
      attr_accessor :returnTypes, :arguments, :static
    end

    def initialize(classifiers, line, getter)
      @lineStart = line
      @getter = getter
      @classifiers = classifiers
    end

    def generate(name, library, clsName, overloads, argumentClassifiers, returnClassifiers)
      ls = @lineStart
      lsT = ls + "  "

      fwdName = "#{name}_fwd"

      output = "#{ls}local #{fwdName} = #{@getter}(\"#{library.name}\", \"#{clsName}\", \"#{@name}\")
#{ls}local #{name} = function(...)\n#{lsT}local argCount = select(\"#\")\n"

      overloads.each do |argCount, overloadData|

        output += generateOverloadCall(
          argCount,
          overloadData,
          argumentClassifiers,
          returnClassifiers)
      end

      output += "#{ls}end"

      return output
    end

  private
    def generateOverloadCall(argCount, overloadData, argumentClassifiers, returnClassifiers)
      returnTypes = getCommonTypeArray(overloadData.returnTypes) { |a| a }
      arguments = getCommonTypeArray(overloadData.arguments) { |a| a.type }

      static = overloadData.static

      expectedArgCount = (static ? 0 : 1) + argCount

      argumentsProcessed = formatArgumentData(arguments, argumentClassifiers)
      
      returnCount, returns, returnProcessed = foratReturnData(returnTypes, returnClassifiers)

      if (returnCount == :unknown || static == :unknown)
        raise "Inconsistent static or return count data for function with classifier #{name}"
      end

      return "#{@lineStart}  if #{expectedArgCount} == argCount then
#{@lineStart}    local #{returns} = fwdName(#{argumentsProcessed})
#{@lineStart}    return #{returnProcessed}
#{@lineStart}  end
"
    end

    def formatArgumentData(arguments, argumentClassifiers)
      return arguments.length.times.map{ |i| 
        processArgument(
          "select(#{i}, ...)",
          argumentClassifiers[i],
          arguments[i].type,
          :param)
      }.join(", ")
    end

    def formatReturnData(returnTypes, returnClassifiers)
      returnCount = returnTypes.length

      returnNames = returnCount.times.map{ |i| "ret#{i}" }
      returns = returnNames.join(", ")

      returnProcessed = returnCount.times.map{ |i| 
        processArgument(returnNames[i], returnClassifiers[i], returnTypes[i], :return)
      }.join(", ")

      return returnCount, returns, returnProcessed
    end

    def processArgument(arg, classifier, type, mode)
      if (classifier == nil || classifier == :none)
        return arg
      end

      return @classifiers[classifier].processArgument(arg, type, mode)
    end

    def getCommonTypeArray(arrays)
      arrayResult = arrays[0]
      raise "No types passed" unless arrayResult

      1..arrays.length do |i|
        array = arrays[i]

        array.each_index do |eIdx|
          if (yeild(array[eIdx]).name != yeild(arrayResult[eIdx]).name)
            raise "non equal return types"
          end
        end

      end

      return arrayResult
    end
  end

end