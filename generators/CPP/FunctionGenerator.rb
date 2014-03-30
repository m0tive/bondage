require_relative "FunctionWrapperGenerator.rb"

module CPP

  class FunctionGenerator
    def initialize(extraFnLineStart, lineStart)
      @lineStart = lineStart
      @extraFunctionLineStart = extraFnLineStart
      reset()
      @wrapperGenerator = FunctionWrapperGenerator.new
    end

    attr_reader :bind, :extraFunctions

    def generateSimpleCall(sig, name)
      fnDef = generateBuildCall(name, sig, false)
      olLs = @lineStart + "  "
      @bind = "#{TYPE_NAMESPACE}::FunctionBuilder::build<
  #{olLs}#{fnDef}
  #{olLs}>"
    end

    def reset()
      @bind = ""
      @calls = { }
      @extraFunctions = []
      @extraFunctionDecls = nil
    end

    def generate(owner, functions)
      reset()

      FunctionVisitor.visit(owner, functions, self)

      name = functions[0].name

      singleCall = nil
      @calls.each do |num, calls|
        raise "Invalid call" unless calls.length()
        if (singleCall)
          singleCall = nil
          break
        end
        singleCall = calls[0]
      end

      olLs = @lineStart + "  "
      ovOlLs = @lineStart + "    "

      if (singleCall)
        @bind = "#{TYPE_NAMESPACE}::FunctionBuilder::build<
#{olLs}#{singleCall}
#{olLs}>(\"#{name}\")"
        return
      end

      argCalls = @calls.map do |num, calls|
        raise "Invalid call" unless calls.length()

        callsJoined = calls.join(",\n#{ovOlLs}")

        "#{TYPE_NAMESPACE}::FunctionBuilder::buildOverloaded<#{num}, std::tuple<
#{ovOlLs}#{callsJoined}
#{ovOlLs}> >"
      end

      callsJoined = argCalls.join(",\n#{olLs}")

@bind = "#{TYPE_NAMESPACE}::FunctionBuilder::buildArgumentCountOverload< std::tuple<
#{olLs}#{callsJoined}
#{olLs}> >(\"#{name}\")"
    end

    def visitFunction(owner, function, functionIndex, argCount)
      callsArray = @calls[argCount]
      if (callsArray == nil)
        callsArray = []
        @calls[argCount] = callsArray
      end

      @wrapperGenerator.generateCall(
        @extraFunctionLineStart,
        owner,
        function,
        functionIndex,
        argCount,
        callsArray,
        @extraFunctions)
    end
  end
end