require_relative "../GeneratorHelper.rb"
require_relative "FunctionWrapperGeneratorHelper.rb"
require_relative "FunctionWrapperArgumentHelper.rb"

module CPP

  def self.toLiteralName(str)
    return str
      .sub("::", "")
      .gsub("::", "_")
      .gsub("<", "lt")
      .gsub(">", "gt")
      .gsub("!", "n")
      .gsub("=", "e")
      .gsub("+", "p")
      .gsub("-", "s")
      .gsub("*", "m")
      .gsub("/", "d")
      .gsub(/[^0-9A-Za-z]/, '_')
  end

  class FunctionWrapperGenerator
    def initialize(ls)
      @lineStart = ls
      @argumentHelper = ArgumentHelper.new
    end

    def reset(owner, function, functionIndex, argCount, types)
      @constructor = function.isConstructor
      @static = function.static || @constructor
      @functionWrapper = nil
      @owner = owner
      @function = function
      @functionIndex = functionIndex
      @name = function.name
      @types = nil

      forceWrapper = argCount != function.arguments.length ||
        @constructor ||
        function.isVariadic ||
        isComplexName(function.name)

      @argumentHelper.reset(forceWrapper, types)
    end

    def generateCall(owner, function, functionIndex, argCount, typedefs, extraFunctions, types)
      reset(owner, function, functionIndex, argCount, types)
      
      if (!@static)
        @argumentHelper.inputs << "#{owner.fullyQualifiedName} &"
      end

      addConstructorOutputArgument(owner)
      addReturnTypeOutputArgument(function)

      # visit arguments of function.
      ArgumentVisitor.visitFunction(owner, function, functionIndex, argCount, @argumentHelper)

      if (@argumentHelper.needsWrapper)
        return generateWrapper(typedefs, extraFunctions)
      end

      typedefName = literalName() + "_t"
      typedefs[typedefName] = generateCallForwarder(@function.fullyQualifiedName, false)
      return typedefName, argCount, false
    end

    def generateWrapper(typedefs, extraFunctions)
      ret, resVar, inArgs, callArgs, initArgs, call = generateCallData()
      callArgs = nil

      extraFnName = literalName()
      typedefName = extraFnName + "_t"
      typedefs[typedefName] = generateCallForwarder(extraFnName, true)

      extraFunctions << Helpers::generateWrapperText(
        @lineStart,
        extraFnName,
        inArgs,
        initArgs,
        call,
        ret,
        @argumentHelper.outputs.length > 0 ? resVar : nil)

      return typedefName, @argumentHelper.inputs.length, true
    end

  private
    def generateCallData()
      ret = returnType()
      resVar = @argumentHelper.resultName()

      # Input args contains the arguments to the function
      inArgs = @argumentHelper.gatherInputArguments().join(', ')

      # Gather the arguments to pass to the function, and add any local copies required to the initArgs.
      # Init args is a list of local copies of variables to init in the function
      callArgs, initArgs = gatherArgumentsAndInitialisedArguments(ret, resVar)
      callArgs = callArgs.join(', ')

      call, returnVal = constructCall(
        callArgs,
        resVar,
        @argumentHelper.outputs)
      returnVal = nil

      return ret, resVar, inArgs, callArgs, initArgs, call
    end

    def addConstructorOutputArgument(owner)
      if (@constructor)
        @argumentHelper.outputs << Helpers::OutputArg.new(:pointer, "#{owner.fullyQualifiedName} *")
      end
    end

    def isComplexName(name)
      # some compilers find bindings with > in the function name hard, this enables us to force an overload
      # which makes the binding simpler.
      return name == "operator>"
    end

    def addReturnTypeOutputArgument(function)
      if (function.returnType)
        @argumentHelper.outputs << Helpers::OutputArg.new(Helpers::argType(function.returnType), function.returnType.bindableName)
      end
    end

    def gatherArgumentsAndInitialisedArguments(ret, resVar)
      initArgs = []

      # If we are returning more than one argument (or the one argument
      # is an output, not a return - we need to store it in a local)
      if (@argumentHelper.outputs.length > 1 || 
        (@argumentHelper.outputs.length > 0 && !hasReturnType()))
        initArgs << "#{ret} #{resVar};"
      end

      call = @argumentHelper.callArguments.map do |arg|
        generateArgAccessor(arg, initArgs)
      end

      return call, initArgs
    end

    def generateArgAccessor(arg, initArgs)
      if (arg.type == :input)
        return arg.callAccessor + @argumentHelper.inputArgPassThrough(arg.source)

      elsif (arg.type == :output)
        return arg.callAccessor + @argumentHelper.outputArgReference(arg.source)
        
      elsif (arg.type == :inout)
        input = @argumentHelper.inputArgPassThrough(arg.inoutSource)
        output = @argumentHelper.outputArgReference(arg.source)
        initArgs << "#{output} = #{arg.dataAccessor} #{input};"
        return arg.callAccessor + output
      end
        
      raise "invalid arg type #{arg.type}"
    end

    def generateCallForwarder(name, usingWrapper)
      sig = signature()

      caller = "bondage::FunctionCaller"
      if (!@static && usingWrapper)
        caller = "Reflect::MethodInjectorBuilder<bondage::FunctionCaller>"
      end

      return "Reflect::FunctionCall<Reflect::FunctionSignature< #{sig} >, &#{name}, #{caller}>"
    end

    def signature()
      result = returnType()

      constness = ""

      ptrType = "(*)"
      types = nil
      if (@argumentHelper.needsWrapper == true)
        types = @argumentHelper.inputs.join(", ")
      else
        if (@function.isConst)
          constness = " const"
        end
        types = @function.arguments.map{ |arg| arg.type.bindableName }.join(", ")
        if (!@static)
          ptrType = "(#{@owner.fullyQualifiedName}::*)"
        end
      end

      return "#{result}#{ptrType}(#{types})#{constness}"
    end

    def constructCall(args, resVar, returns)
      # function accessor finds a way to call this function
      # depending on constructor, static or member calls.
      call = "#{functionAccessor()}(#{args})"

      # [hasReturnType] is only true for functions returning something
      # not for functions which have outputs.
      if (hasReturnType())
        if (returns.length > 1)
          call = "#{@argumentHelper.outputArgReference(0)} = #{call}"
        else
          type = "auto"
          if (returns[0].type == :reference)
            type = "auto &&"
          end
          call = "#{type} #{resVar} = #{call}"
        end
      end

      return call
    end

    def functionAccessor
      if (@constructor)
        return "#{TYPE_NAMESPACE}::WrappedClassHelper< #{@owner.fullyQualifiedName} >::create"
      end

      if (!@function.static)
        return "#{@argumentHelper.inputArgName(0)}.#{@function.name}"
      end

      return @function.fullyQualifiedName
    end

    def hasReturnType()
      return @constructor || @function.returnType
    end

    def returnType
      if (@argumentHelper.outputs.length == 0)
        return "void"
      elsif (@argumentHelper.outputs.length == 1)
        return @argumentHelper.outputs[0].name
      end

      args = @argumentHelper.outputs.map{ |a| a.name }

      return "std::tuple< #{args.join(', ')} >"
    end

    def literalName
      literalName = CPP::toLiteralName(@function.fullyQualifiedName())
      if (@functionIndex)
        literalName += "_overload#{@functionIndex}"
      end
      return literalName
    end
  end
end