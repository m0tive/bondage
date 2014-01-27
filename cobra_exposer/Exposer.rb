require_relative "ExposeAST.rb"

class Exposer
  def initialize(library, debug)
    @debugOutput = debug
    @exposedClasses = library.classes.select do |cls| canExposeClass(cls) end
    @exposedClassPaths = @exposedClasses.map{ |cls| cls.fullyQualifiedName }
  end

  attr_reader :exposedClasses

  def canExposeMethod(fn)
    if(fn.isExposed == nil)
      fn.setExposed((fn.returnType == nil || canExposeTypeImpl(fn.returnType)) && fn.arguments.all?{ |param| canExposeType(param) })
    end

    return fn.isExposed
  end

  def canExposeType(obj)
    if(obj == nil)
      return true
    end

    return canExposeTypeImpl(obj[:type])
    
  end

private
  def canExposeTypeImpl(type)
    if(type.isBasicType())
      return true
    end

    if(type.isPointer())
      pointed = type.pointeeType()
      if(pointed.isPointer())
        return false
      end

      return canExposeTypeImpl(pointed)
    end

    if(type.isLValueReference() || type.isRValueReference())
      pointed = type.pointeeType()
      if(pointed.isPointer())
        return false
      end

      return canExposeTypeImpl(pointed)
    end
    
    name = type.name

    if(@exposedClassPaths.any?{ |path| path[-name.length, path.length] == name })
      return true
    end

    puts "not local: #{name}"

    return false
  end

  def canExposeClass(cls)
    if(cls.isExposed == nil)
      hasExposeComment = cls.comment.hasCommand("expose")
      if(@debugOutput)
        puts "#{hasExposeComment}\t#{cls.name}"
      end

      if(!hasExposeComment)
        cls.setExposed(false)
        return false
      end

      willExpose = 
        !cls.isTemplated && 
        !cls.name.empty?

      if(!willExpose || @debugOutput)
        puts "\tExposeRequested: #{hasExposeComment}\tTemplate: #{cls.isTemplated}"
      end
      raise "Unable to expose requested class #{cls.name}" if not willExpose 
      cls.setExposed(willExpose)
      return willExpose
    end

    return cls.isExposed
  end
end