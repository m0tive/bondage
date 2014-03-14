
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
        puts "- #{owner.fullyQualifiedName}::#{fn.name}"
        puts " - requested not to."
        return
      end

      access = false
      returnType = false
      arguments = false

      # methods must be public to expose
      access = fn.accessSpecifier == :public || fn.accessSpecifier == :invalid
      if (!@debug && (!access && !mustExpose))
        return false
      end

      notOverride = !fn.isOverride
      if (!@debug && (!notOverride && !mustExpose))
        return false
      end

      # methods must have a partially exposed return type (it or a derived class)
      returnType = (fn.returnType == nil || @typeExposer.canExposeType(fn.returnType, true))
      if (!@debug && (!returnType && !mustExpose))
        return false
      end
      
      # methods arguments must all be exposed fully.
      arguments = true
      fn.arguments.each do |arg|
        if (!arg.hasDefault && !canExposeArgument(arg))
          arguments = false
          break
        end
      end
      if (!@debug && (!arguments && !mustExpose))
        return false
      end

      canExpose = access && notOverride && returnType && arguments

      if(@debug || (!canExpose && mustExpose))
        puts "- #{owner.fullyQualifiedName}::#{fn.name}"
        puts " - accessible: #{access}"
        puts " - not override: #{notOverride}"
        puts " - return type: #{returnType}"
        puts " - arg types: #{arguments}"
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

    type = obj.type

    if obj.input? then
      if (!@typeExposer.canExposeType(type, false))
        return false
      end
    end

    if obj.output? then
      outputType = obj.type
      if (outputType.isLValueReference() || outputType.isPointer())
        outputType = outputType.pointeeType()
      else
        raise "Invalid output type - expected pointer or reference."
      end

      if (!@typeExposer.canExposeType(outputType, true))
        return false
      end
    end

    return true
  end

end