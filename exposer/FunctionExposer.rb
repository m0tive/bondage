
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
      exposeFlag = fn.comment.hasCommand("expose")
      cantExpose = fn.comment.hasCommand("noexpose")
      mustExpose = exposeFlag
      shouldExpose = exposeFlag || !owner.kind_of?(NamespaceItem)

      if (mustExpose && cantExpose)
        raise "Cannot require and refuse exposure for a single type #{owner.fullyQualifiedName}::#{fn.name}"
      end

      fn.setExposed(false)
      if (cantExpose || !shouldExpose)
        if (@debug)
          puts "- #{owner.fullyQualifiedName}::#{fn.name}"
          puts " - asked to expose #{exposeFlag} automatically expose #{shouldExpose}"
          puts " - requested not to."
        end
        return
      end

      canExpose = 
        isFunctionAccessible(fn) &&
        isFunctionNotOverride(fn) &&
        isReturnTypeExposed(fn) &&
        areAllArgumentTypesExposable(fn)

      if(@debug || (!canExpose && mustExpose))
        puts "- #{owner.fullyQualifiedName}::#{fn.name}"
        puts " - accessible: #{isFunctionAccessible(fn)}"
        puts " - not override: #{isFunctionNotOverride(fn)}"
        puts " - return type: #{isReturnTypeExposed(fn)}"
        puts " - arg types: #{areAllArgumentTypesExposable(fn)}"
        puts " - combined: #{canExpose}"
      end

      if (!canExpose && mustExpose)
        raise "Unable to expose required method #{owner.fullyQualifiedName}::#{fn.name}" 
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

private

  def isFunctionAccessible(fn)
    return fn.accessSpecifier == :public || fn.accessSpecifier == :invalid
  end

  def isFunctionNotOverride(fn)
    return !fn.isOverride
  end

  def isReturnTypeExposed(fn)
    return fn.returnType == nil || @typeExposer.canExposeType(fn.returnType, true)
  end

  def areAllArgumentTypesExposable(fn)
    arguments = true
    fn.arguments.each do |arg|
      if (!arg.hasDefault && !canExposeArgument(arg))
        arguments = false
        break
      end
    end
    return arguments
  end

end