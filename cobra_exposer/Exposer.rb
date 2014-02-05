require_relative "ExposeAST.rb"
require_relative "ClassMetaData.rb"
require "set"

class Exposer
  def initialize(visitor, debug)
    @debugOutput = debug
    @exposedClasses = visitor.classes.select do |cls| canExposeClass(cls) end
    @partiallyExposedClasses = visitor.classes.select do |cls| canPartiallyExposeClass(cls) end
    @exposedClassPaths = @exposedClasses.reduce(Set.new) { |set, cls| set.add(cls.fullyQualifiedName) }

    @metaData = MetaDataGenerator.fromClasses(@exposedClasses, @partiallyExposedClasses)
    puts "Exporting class data for '#{visitor.library.name}' to '#{visitor.library.autogenPath}'"
    @metaData.export(visitor.library.autogenPath)

    mergeDependencyClasses(@metaData, visitor.library)
  end

  attr_reader :exposedClasses, :partiallyExposedClasses, :exposedClassPaths

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
  def mergeDependencyClasses(dataToMerge, lib)
    lib.dependencies.each do |dep| 
      mergeDependencyClasses(dataToMerge, dep)

      metaData = MetaDataGenerator.import(dep.autogenPath)
      dataToMerge.merge(metaData)
    end
  end

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

    fullName = "::#{name}"

    if(@exposedClassPaths.include?(fullName))
      return true
    end

    if(@dependencyClassPaths.include?(fullName))
      return true
    end

    puts "not exposing #{fullName}"

    return false
  end

  def canPartiallyExposeClass(cls)
    return canExposeClass(cls)
  end

  def canExposeClass(cls)
    if(cls.isExposed == nil)
      hasExposeComment = cls.comment.hasCommand("expose")
      if(@debugOutput)
        puts "#{hasExposeComment ? "Y" : "N"}\t#{cls.name}"
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