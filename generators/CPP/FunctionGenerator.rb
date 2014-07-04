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

    attr_reader :bind, :extraFunctions, :typedefs

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
      @typedefs = { }
      @extraFunctions = []
      @extraFunctionDecls = nil
      @types = types
    end

    def gatherFunctions(owner, exposer, files)
      functions = exposer.findExposedFunctions(owner)
      
      typedefs = []
      methods = []
      extraMethods = []

      types = Set.new()

      # for each function, work out how best to call it.
      functions.sort.each do |name, fns|
        generate(owner, fns, exposer, types)

        methods << bind
        extraMethods = extraMethods.concat(extraFunctions)
        @typedefs.each do |k,v|
          typedefs << "struct #{k} : #{v} { };"
        end
      end

      files.merge(types.map { |e|
        cls = exposer.allMetaData.findClass(e)
        raise "Failed to find dependency '#{e}' #{exposer.allMetaData.debugTypes}" unless cls

        next cls.library.root + "/" + cls.filename
      })

      return methods, extraMethods, typedefs
    end

    def generateFunctionArray(typedefs, binders, extraMethods, namingHelper)
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
        methodsInfo = "\n" +  typedefs.join("\n") + "\n\nconst #{TYPE_NAMESPACE}::Function #{methodsLiteral}[] = {\n#{methodsSource}\n};\n\n"
      end

      return methodsLiteral, methodsInfo, extraMethodSource
    end

    def generate(owner, functions, exposer, types)
      reset(types)

      name = functions[0].name

      FunctionVisitor.visit(owner, functions, self, exposer, @debug)

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

        overloadTypedef = literalName(owner, name, num)

        if (calls.length > 1)
          callsJoined = calls.join(",\n#{ovOlLs}")

          @typedefs[overloadTypedef] = "Reflect::FunctionArgCountSelectorBlock<#{num}, Reflect::FunctionArgumentTypeSelector<
#{ovOlLs}#{callsJoined}
#{ovOlLs}> >"
        else
          @typedefs[overloadTypedef] = "Reflect::FunctionArgCountSelectorBlock<#{num},
#{ovOlLs}#{calls[0]}
#{ovOlLs}>"
        end

        next overloadTypedef
      end

      callsJoined = argCalls.join(",\n#{olLs}")

      overloadTypedef = literalName(owner, name)
      @typedefs[overloadTypedef] = "Reflect::FunctionArgumentCountSelector<
#{olLs}#{callsJoined}
#{olLs}>"

      @bind = "#{TYPE_NAMESPACE}::FunctionBuilder::buildOverload< #{overloadTypedef} >(\"#{name}\")"
    end

    def visitFunction(owner, function, functionIndex, argCount)
      thisCount = function.static ? 0 : 1
      expectedCount = thisCount + argCount

      callsArray = @calls[expectedCount]
      if (callsArray == nil)
        callsArray = []
        @calls[expectedCount] = callsArray
      end

      @wrapperGenerator.generateCall(
        owner,
        function,
        functionIndex,
        argCount,
        callsArray,
        @typedefs,
        @extraFunctions,
        @types)
    end

    def literalName(owner, name, id=nil)
      niceName = name.gsub(/[^0-9A    -Za-z]/, '')
      if (id != nil)
        return "#{owner.name}_#{niceName}_overload_#{id}"
      else
        return "#{owner.name}_#{niceName}_overload"
      end
    end
  end
end