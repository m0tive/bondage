
# FunctionExposer helps decide if a function can be exposed, 
# given a set of types which are exposable.
#
# Not directly usable - use Exposer instead
#
class FunctionExposer
  def initialize(typeExposer)
    @typeExposer = typeExposer
  end

  # find if a method [fn], a FunctionItem class can be exposed in the current library.
  def canExposeMethod(fn)
    if(fn.isExposed == nil)
      # methods must be public to expose
      canExpose = fn.accessSpecifier == :public
      # methods must have a partially exposed return type (it or a derived class)
      canExpose = canExpose && (fn.returnType == nil || @typeExposer.canExposeType(fn.returnType, true))
      # methods arguments must all be exposed fully.
      canExpose = canExpose && fn.arguments.all?{ |param| canExposeArgument(param) }

      fn.setExposed(canExpose)
    end

    return fn.isExposed
  end

  # find if an argument [obj], an ArgumentItem can be exposed.
  def canExposeArgument(obj)
    if(obj == nil)
      return true
    end

    return @typeExposer.canExposeType(obj.type, false)
  end

end