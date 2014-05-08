
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
      @inputs << arg.type.nameWithTypedefs
      @callArguments << Helpers::WrapperArg.new(:inout, outIdx, inIdx, access)
      @needsWrapper = true
    end
    
    def visitInputArgument(fn, idx, cnt, arg)
      inIdx = @inputs.length
      @inputs << arg.type.nameWithTypedefs
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
      name = arg.type.nameWithTypedefs
      accessor = Helpers::argType(arg.type)

      if (arg.type.isPointer)
        name = arg.type.pointeeType().nameWithTypedefs
      elsif (arg.type.isLValueReference)
        name = arg.type.pointeeType().nameWithTypedefs
      elsif (arg.type.isRValueReference)
        raise "R value reference as an output? this needs some thought."
      end
      @outputs << Helpers::OutputArg.new(accessor, name)

      return outIdx, accessor
    end
  end
end