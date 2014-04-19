require_relative "../GeneratorHelper.rb"
require_relative "FunctionWrapperGeneratorHelper.rb"

module CPP

  class ArgumentHelper
    def reset(forceWrapper)
      @inputs = []
      @outputs = []
      @callArguments = []
      @needsWrapper = forceWrapper
    end

    attr_accessor :inputs, :outputs, :callArguments, :needsWrapper

    def visitInputOutputArgument(fn, idx, cnt, arg)
      outIdx, access = addOutputArgumentHelper(arg)

      inIdx = @inputs.length
      @inputs << arg.type.name
      @callArguments << Helpers::WrapperArg.new(:inout, outIdx, inIdx, access)
      @needsWrapper = true
    end
    
    def visitInputArgument(fn, idx, cnt, arg)
      inIdx = @inputs.length
      @inputs << arg.type.name
      @callArguments << Helpers::WrapperArg.new(:input, inIdx)
    end

    def visitOutputArgument(fn, idx, cnt, arg)
      outIdx, access = addOutputArgumentHelper(arg)

      @callArguments << Helpers::WrapperArg.new(:output, outIdx, nil, access)
      @needsWrapper = true
    end

    def inputArgPassThrough(i)
      type = @inputs[i]
      return "std::forward<#{type}>(#{inputArgName(i)})"
    end

    def inputArgName(i)
      return "inputArg#{i}"
    end

    def resultName
      return "result"
    end

    def gatherInputArguments()
      return @inputs.each_with_index.map do |arg, i|
        "#{arg} #{inputArgName(i)}"
      end
    end

    def outputArgReference(i)
      if (@outputs.length > 1)
        return "std::get<#{i}>(#{resultName()})"
      end

      return resultName()
    end

  private
    def addOutputArgumentHelper(arg)
      outIdx = @outputs.length
      name = arg.type.name
      accessor = Helpers::argType(arg.type)

      if (arg.type.isPointer)
        name = arg.type.pointeeType().name
      elsif (arg.type.isLValueReference)
        name = arg.type.pointeeType().name
      elsif (arg.type.isRValueReference)
        raise "R value reference as an output? this needs some thought."
      end
      @outputs << Helpers::OutputArg.new(accessor, name)

      return outIdx, accessor
    end
  end

  class FunctionWrapperGenerator
    def initialize(ls)
      @lineStart = ls
      @argumentHelper = ArgumentHelper.new
    end

    def reset(owner, function, functionIndex, argCount)
      @constructor = function.isConstructor
      @static = function.static || @constructor
      @functionWrapper = nil
      @owner = owner
      @function = function
      @functionIndex = functionIndex
      @name = function.name
      
      @argumentHelper.reset(argCount != function.arguments.length || @constructor)
    end

    def generateCall(owner, function, functionIndex, argCount, calls, extraFunctions)
      reset(owner, function, functionIndex, argCount)
      
      if (!@static)
        @argumentHelper.inputs << "#{owner.fullyQualifiedName} &"
      end

      addConstructorOutputArgument(owner)
      addReturnTypeOutputArgument(function)

      # visit arguments of function.
      ArgumentVisitor.visitFunction(owner, function, functionIndex, argCount, @argumentHelper)

      if (@argumentHelper.needsWrapper)
        generateWrapper(calls, extraFunctions)
      else
        sig = signature()
        calls << "#{TYPE_NAMESPACE}::FunctionBuilder::buildCall< #{sig}, &#{@function.fullyQualifiedName} >"
      end
    end

    def generateWrapper(calls, extraFunctions)
      ret = returnType()
      resVar = @argumentHelper.resultName()

      hasReturnType = @constructor || @function.returnType

      # Input args contains the arguments to the function
      inArgs = @argumentHelper.gatherInputArguments().join(', ')

      # Gather the arguments to pass to the function, and add any local copies required to the initArgs.
      # Init args is a list of local copies of variables to init in the function
      args, initArgs = gatherArgumentsAndInitialisedArguments(hasReturnType, ret, resVar)
      args = args.join(', ')

      call, returnVal = constructCall(
        args,
        hasReturnType,
        resVar,
        @argumentHelper.outputs)

      extraFnName = literalName()
      calls << generateCallForwarder(extraFnName)

      extraFunctions << Helpers::generateWrapperText(
        @lineStart,
        extraFnName,
        inArgs,
        initArgs,
        call,
        ret,
        @argumentHelper.outputs.length > 0 ? resVar : nil)
    end

  private

    def addConstructorOutputArgument(owner)
      if (@constructor)
        @argumentHelper.outputs << Helpers::OutputArg.new(:pointer, "#{owner.fullyQualifiedName} *")
      end
    end

    def addReturnTypeOutputArgument(function)
      if (function.returnType)
        @argumentHelper.outputs << Helpers::OutputArg.new(Helpers::argType(function.returnType), function.returnType.name)
      end
    end

    def gatherArgumentsAndInitialisedArguments(hasReturnType, ret, resVar)
      initArgs = []

      # If we are returning more than one argument (or the one argument
      # is an output, not a return - we need to store it in a local)
      if (@argumentHelper.outputs.length > 1 || 
        (@argumentHelper.outputs.length > 0 && !hasReturnType))
        initArgs << "#{ret} #{resVar};"
      end

      call = @argumentHelper.callArguments.map do |arg|
        if (arg.type == :input)
          next arg.callAccessor + @argumentHelper.inputArgPassThrough(arg.source)
        elsif (arg.type == :output)
          next arg.callAccessor + @argumentHelper.outputArgReference(arg.source)
        elsif (arg.type == :inout)
          input = @argumentHelper.inputArgPassThrough(arg.inoutSource)
          output = @argumentHelper.outputArgReference(arg.source)
          initArgs << "#{output} = #{arg.dataAccessor} #{input};"
          next arg.callAccessor + output
        else
          raise "invalid arg type #{arg.type}"
        end
      end

      return call, initArgs
    end

    def generateCallForwarder(name)
      sig = signature()
      callType = @static ? "buildCall" : "buildMemberStandinCall"
      return "#{TYPE_NAMESPACE}::FunctionBuilder::#{callType}< #{sig}, &#{name} >"
    end

    def signature()
      result = returnType()

      ptrType = "(*)"
      types = nil
      if (@argumentHelper.needsWrapper)
        types = @argumentHelper.inputs.join(", ")
      else
        types = @function.arguments.map{ |arg| arg.type.name }.join(", ")
        if (!@static)
          ptrType = "(#{@owner.fullyQualifiedName}::*)"
        end
      end

      return "#{result}#{ptrType}(#{types})"
    end

    def constructCall(args, hasReturnType, resVar, returns)
      # function accessor finds a way to call this function
      # depending on constructor, static or member calls.
      call = "#{functionAccessor()}(#{args})"

      # [hasReturnType] is only true for functions returning something
      # not for functions which have outputs.
      if (hasReturnType)
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
      fullyQualified = @function.fullyQualifiedName()
      literalName = fullyQualified.sub("::", "").gsub("::", "_")
      if (@functionIndex)
        literalName += "_overload#{@functionIndex}"
      end
      return literalName
    end
  end
end