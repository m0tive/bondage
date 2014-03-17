
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
        visitor.visitFunction(owner, fn, functionIndex, i)
        functionIndex += 1
      end
    end

    visitor.visitFunction(owner, fn, functionIndex, fn.arguments.length)
    functionIndex += 1
    return functionIndex
  end
end

class ArgumentVisitor
  def self.visitFunction(owner, fn, functionIndex, argCount, visitor)
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
  end
end