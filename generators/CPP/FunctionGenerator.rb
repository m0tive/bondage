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
      @calls = []
      @extraFunctions = []
      @extraFunctionDecls = nil
    end

    def generate(owner, functions)
      reset()

      FunctionVisitor.visit(owner, functions, self)

      name = functions[0].name

      caller = "build"
      list = nil

      olLs = @lineStart + "  "

      if (@calls.length == 1)
        caller = "build"
        list = @calls[0]
      elsif(@calls.length > 1)
        caller = "buildOverloaded"
        list = @calls.join(",\n#{olLs}")
      end


      @bind = 
"#{TYPE_NAMESPACE}::FunctionBuilder::#{caller}<
#{olLs}#{list}
#{olLs}>(\"#{name}\")"
    end

    def visitFunction(owner, function, functionIndex, argCount)
      @wrapperGenerator.generateCall(
        @extraFunctionLineStart,
        owner,
        function,
        functionIndex,
        argCount,
        @calls,
        @extraFunctions)
    end
  end
end