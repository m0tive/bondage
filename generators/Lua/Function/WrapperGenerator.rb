
module Lua

  module Function

    class WrapperGenerator
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

      def generate(
          wrapperName,
          name,
          library,
          clsName,
          overloads,
          argumentClassifiers,
          returnClassifiers,
          requiredClasses)
        ls = @lineStart
        lsT = ls + "  "

        fwdName = "#{wrapperName}_fwd"

        output = "#{ls}local #{fwdName} = #{@getter}(\"#{library.name}\", \"#{clsName}\", \"#{name}\")
#{ls}local #{wrapperName} = function(...)\n#{lsT}local argCount = select(\"#\", ...)\n"

        overloads.each do |argCount, overloadData|

          output += generateOverloadCall(
            argCount,
            overloadData,
            argumentClassifiers,
            returnClassifiers,
            requiredClasses,
            fwdName)
        end

        output += "#{ls}end"

        return output
      end

    private
      def generateOverloadCall(argCount, overloadData, argumentClassifiers, returnClassifiers, requiredClasses, fwdName)
        returnTypes = getCommonTypeArray(overloadData.returnTypes) { |a| a }
        arguments = getCommonTypeArray(overloadData.arguments) { |a| a.type }

        static = overloadData.static
        if (static == :unknown)
          raise "Inconsistent static or return count data for function with classifier #{name}"
        end

        expectedArgCount = (static ? 0 : 1) + argCount

        argumentsProcessed = formatArgumentData(arguments, argumentClassifiers, requiredClasses, static)
        
        returnCount, returns, returnProcessed = formatReturnData(returnTypes, returnClassifiers, requiredClasses)


        call = ""
        if (returnCount == 0)
          raise "Return data for function without returns" unless returnProcessed.empty?

          call = "#{@lineStart}    return #{fwdName}(#{argumentsProcessed})"
        else
          call = "#{@lineStart}    local #{returns} = #{fwdName}(#{argumentsProcessed})
#{@lineStart}    return #{returnProcessed}"
        end

        return "#{@lineStart}  if #{expectedArgCount} == argCount then
#{call}
#{@lineStart}  end
"
      end

      def formatArgumentData(arguments, argumentClassifiers, requiredClasses, static)
        extra = 0

        thisArg = ""
        if (!static)
          thisArg = "select(1, ...)"
          if (arguments.length > 0)
            thisArg += ", "
          end
          extra = 1
        end

        return thisArg + arguments.length.times.map{ |i|
          processArgument(
            "select(#{i+1+extra}, ...)",
            argumentClassifiers[i],
            arguments[i].type,
            :param,
            requiredClasses)
        }.join(", ")
      end

      def formatReturnData(returnTypes, returnClassifiers, requiredClasses)
        returnCount = returnTypes.length

        returnNames = returnCount.times.map{ |i| "ret#{i}" }
        returns = returnNames.join(", ")

        returnProcessed = returnCount.times.map{ |i| 
          processArgument(returnNames[i], returnClassifiers[i], returnTypes[i], :return, requiredClasses)
        }.join(", ")

        return returnCount, returns, returnProcessed
      end

      def processArgument(arg, classifierName, type, mode, requiredClasses)
        if (classifierName == nil || classifierName == :none)
          return arg
        end

        classifier = @classifiers[classifierName]
        raise "Invalid classifier '#{classifierName}' specified for #{arg}
Available classifiers: #{@classifiers.keys}" unless classifier

        return classifier.processArgument(arg, type, mode, requiredClasses)
      end

      def getCommonTypeArray(arrays)
        arrayResult = arrays[0]
        raise "No types passed" unless arrayResult

        arrays.length.times do |i|
          array = arrays[i]

          array.each_index do |eIdx|
            if (yield(array[eIdx]).name != yield(arrayResult[eIdx]).name)
              raise "non equal return types"
            end
          end
        end

        return arrayResult
      end
    end
  end
end