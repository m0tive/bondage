
# FunctionExposer helps decide if a function can be exposed, 
# given a set of types which are exposable.
#
# Not directly usable - use Exposer instead
#
class FunctionExposer
  def initialize(typeExposer, debug=false)
    @typeExposer = typeExposer
    @debug = debug
  end

  # find if a method [fn], a FunctionItem class can be exposed in the current library.
  def canExposeMethod(owner, fn)
    if(fn.isExposed == nil)
      mustExpose = fn.comment.hasCommand("expose")
      cantExpose = fn.comment.hasCommand("noexpose")

      if (mustExpose && cantExpose)
        raise "Cannot require and refuse exposure for a single type #{owner.fullyQualifiedName}::#{fn.name}"
      end

      fn.setExposed(false)
      if (cantExpose)
        return
      end

      access = false
      returnType = false
      arguments = false

      # methods must be public to expose
      access = fn.accessSpecifier == :public || fn.accessSpecifier == :invalid
      if (!access && !mustExpose)
        return false
      end

      # methods must have a partially exposed return type (it or a derived class)
      returnType = (fn.returnType == nil || @typeExposer.canExposeType(fn.returnType, true))
      if (!returnType && !mustExpose)
        return false
      end
      
      # methods arguments must all be exposed fully.
      arguments = fn.arguments.all?{ |param| canExposeArgument(param) }
      if (!arguments && !mustExpose)
        return false
      end

      canExpose = access && returnType && arguments

      if(@debug or (!canExpose && mustExpose))
        puts "- #{owner.fullyQualifiedName}::#{fn.name}"
        puts " - accessible: #{canExpose}"
        puts " - return type: #{canExpose}"
        puts " - arg types: #{canExpose}"
        puts " - #{canExpose}"

        if (mustExpose)
          raise "Unable to expose required method #{owner.fullyQualifiedName}::#{fn.name}" 
        end
      end

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