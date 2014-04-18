
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
      lsT2 = lsT + "  "
      lsT3 = lsT2 + "  "

      fwdName = "#{name}_fwd"

      output = "#{ls}local #{fwdName} = #{@getter}(\"#{library.name}\", \"#{clsName}\", \"#{@name}\")
#{ls}local #{name} = function(...)\n#{lsT}local argCount = select(\"#\")\n"
      overloads.each do |argCount, overloadData|
        returnTypes = getCommonTypeArray(overloadData.returnTypes)
        arguments = getCommonArgumentArray(overloadData.arguments)

        returnCount = overloadData.returnTypes[0].length
        static = overloadData.static

        if (returnCount == :unknown || static == :unknown)
          raise "Inconsistent static or return count data for function with classifier #{name}"
        end

        expectedArgCount = (static ? 0 : 1) + argCount

        returns = returnCount.times.map{ |i| "ret#{i}" }.join(", ")

        argumentsProcessed = argCount.times.map{ |i| 
          processArgument("select(#{i}, ...)", argumentClassifiers[i], arguments[i].type, :param)
        }.join(",\n#{lsT3}")
        
        returnProcessed = returnCount.times.map{ |i| 
          processArgument("ret#{i}", returnClassifiers[i], returnTypes[i], :return)
        }.join(", ")

        output += "#{lsT}if #{expectedArgCount} == argCount then
#{lsT2}local #{returns} = fwdName(#{argumentsProcessed})
#{lsT2}return #{returnProcessed}
#{lsT}end
"
      end

      output += "#{ls}end"

      return output
    end

  private

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
          if (array[eIdx].name != arrayResult[eIdx].name)
            raise "non equal return types"
          end
        end

      end

      return arrayResult
    end

    def getCommonArgumentArray(arrays)
      arrayResult = arrays[0]
      raise "No arguments passed" unless arrayResult

      1..arrays.length do |i|
        array = arrays[i]

        array.each_index do |eIdx|
          if (array[eIdx].name != arrayResult[eIdx].name)
            raise "non equal argument types"
          end
        end
      end

      return arrayResult
    end
  end

end