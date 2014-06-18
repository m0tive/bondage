require_relative "FunctionWrapperGenerator.rb"

module CPP

  class FunctionGenerator
    def initialize(extraFnLineStart, lineStart, debug=false)
      @lineStart = lineStart
      @extraFunctionLineStart = extraFnLineStart
      @debug = debug
      reset(nil)
      @wrapperGenerator = FunctionWrapperGenerator.new(@extraFunctionLineStart)
    end

    attr_reader :bind, :extraFunctions

    def generateSimpleCall(sig, name)
      fnDef = generateBuildCall(name, sig, false)
      olLs = @lineStart + "  "
      @bind = "#{TYPE_NAMESPACE}::FunctionBuilder::build<
  #{olLs}#{fnDef}
  #{olLs}>"
    end

    def reset(types)
      @bind = ""
      @files = nil
      @calls = { }
      @extraFunctions = []
      @extraFunctionDecls = nil
      @types = types
    end

    def gatherFunctions(owner, exposer, files)
      functions = exposer.findExposedFunctions(owner)
      
      methods = []
      extraMethods = []

      types = Set.new()

      # for each function, work out how best to call it.
      functions.sort.each do |name, fns|
        generate(owner, fns, exposer, types)

        methods << bind
        extraMethods = extraMethods.concat(extraFunctions)
      end

      files.merge(types.map { |e|
        cls = exposer.allMetaData.findClass(e)
        raise "Failed to find dependency '#{e}' #{exposer.allMetaData.debugTypes}" unless cls

        next cls.library.root + "/" + cls.filename
      })

      return methods, extraMethods
    end

    def generateFunctionArray(binders, extraMethods, namingHelper)
      methodsSource = ""
      if (binders.length > 0)
        methodsSource = "  " + binders.join(",\n  ")
      end
      extraMethodSource = ""
      if (extraMethods.length > 0)
        extraMethodSource = "\n" + extraMethods.join("\n\n") + "\n"
      end


      methodsInfo = ""
      methodsLiteral = "nullptr"
      if (binders.length > 0)
        methodsLiteral = namingHelper + "_methods";
        methodsInfo = "\nconst #{TYPE_NAMESPACE}::Function #{methodsLiteral}[] = {\n#{methodsSource}\n};\n\n"
      end

      return methodsLiteral, methodsInfo, extraMethodSource
    end

    def generate(owner, functions, exposer, types)
      reset(types)

      FunctionVisitor.visit(owner, functions, self, exposer, @debug)

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

        if (calls.length > 1)
          callsJoined = calls.join(",\n#{ovOlLs}")

        "Reflect::FunctionArgCountSelectorBlock<#{num}, Reflect::FunctionArgumentTypeSelector<
#{ovOlLs}#{callsJoined}
#{ovOlLs}> >"
        else
          "Reflect::FunctionArgCountSelectorBlock<#{num},
#{ovOlLs}#{calls[0]}
#{ovOlLs}>"
        end
      end

      callsJoined = argCalls.join(",\n#{olLs}")

@bind = "#{TYPE_NAMESPACE}::FunctionBuilder::buildOverload< Reflect::FunctionArgumentCountSelector<
#{olLs}#{callsJoined}
#{olLs}> >(\"#{name}\")"
    end

    def visitFunction(owner, function, functionIndex, argCount)
      callsArray = @calls[argCount]
      if (callsArray == nil)
        callsArray = []
        thisCount = function.static ? 0 : 1
        @calls[argCount + thisCount] = callsArray
      end

      @wrapperGenerator.generateCall(
        owner,
        function,
        functionIndex,
        argCount,
        callsArray,
        @extraFunctions,
        @types)
    end
  end
end