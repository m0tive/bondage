
class FunctionVisitor
  def self.visit(owner, fns, visitor, exposer=nil)
    functionIndex = 0
    fns.each do |fn|
      functionIndex += FunctionVisitor.visitFunction(owner, fn, functionIndex, visitor, exposer)
    end
  end

  def self.visitFunction(owner, fn, functionIndex, visitor, exposer)
    fn.arguments.each_index do |i|
      arg = fn.arguments[i]
      if (exposer && !arg.functionExposer.canExposeArgument(arg))
        return functionIndex
      end

      if (arg.hasDefault && arg.input?)
        FunctionVisitor.visitOverload(owner, fn, functionIndex, i, visitor)
        functionIndex += 1
      end
    end

    FunctionVisitor.visitOverload(owner, fn, functionIndex, fn.arguments.length, visitor)
    functionIndex += 1
    return functionIndex
  end

  def self.visitOverload(owner, fn, functionIndex, argCount, visitor)
    visitor.visitFunction(owner, fn, functionIndex, argCount)

    argCount.times do |n|
      arg = fn.arguments[n]
      if (arg.input? && arg.output?)
        visitor.visitInputOutputArgument(fn, n, argCount, arg)
      elsif (arg.input?)
        visitor.visitInputArgument(fn, n, argCount, arg)
      elsif (arg.output?)
        visitor.visitOutputArgument(fn, n, argCount, arg)
      else
        raise "Invalid Input output combination?"
      end
    end

    visitor.visitFunctionComplete(fn, argCount)
  end
end