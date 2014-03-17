require_relative "FunctionWrapperGenerator.rb"

class FunctionGenerator
  def initialize(lineStart)
    @lineStart = lineStart
    reset()
    @wrapperGenerator = FunctionWrapperGenerator.new
  end

  attr_reader :bind, :extraFunctions

  def generateSimpleCall(sig, name)
    fnDef = generateBuildCall(name, sig, false)
    olLs = @lineStart + "  "
    @bind = "cobra::function_builder::build<
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
      caller = "build_overloaded"
      list = @calls.join(",\n#{olLs}")
    end


    @bind = 
"cobra::function_builder::#{caller}<
#{olLs}#{list}
#{olLs}>(\"#{name}\")"
  end

  def visitFunction(owner, function, functionIndex, argCount)
    @wrapperGenerator.generateCall(
      @lineStart,
      owner,
      function,
      functionIndex,
      argCount,
      @calls,
      @extraFunctions)
  end
end