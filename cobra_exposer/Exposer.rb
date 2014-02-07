require_relative "ExposeAST.rb"
require_relative "ClassMetaData.rb"
require "set"

class Exposer
  def initialize(visitor, debug)
    @debugOutput = debug
    
    @allMetaData = MetaDataGenerator.new()
    mergeDependencyClasses(@allMetaData, visitor.library)

    exposedClasses = visitor.classes.select do |cls| canExposeClass(cls) end
    partiallyExposedClasses = []
    visitor.classes.each do |cls|
      if(canPartiallyExposeClass(cls, partiallyExposedClasses))
        partiallyExposedClasses << cls
      end
    end

    @exposedMetaData = MetaDataGenerator.fromClasses(exposedClasses, partiallyExposedClasses)
    puts "Exporting class data for '#{visitor.library.name}' to '#{visitor.library.autogenPath}'"
    @exposedMetaData.export(visitor.library.autogenPath)

    @allMetaData.merge(@exposedMetaData)
  end

  attr_reader :exposedMetaData, :allMetaData

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

    if(@allMetaData.fullyExposed?(fullName))
      return true
    end

    puts "not exposing #{fullName}"

    return false
  end

  def canPartiallyExposeClass(cls, otherPartiallyExposedTypes)
    if(canExposeClass(cls))
      return true
    end

    validSuperClasses = {}

    puts "####{cls.name}"

    anyExposed = false
    cls.superClasses.each do |cls|
      clsPath = cls[:name]
      puts ">>> #{cls[:name]}"
    if false then
        validSuperClasses << cls
        allMetaData.partiallyExposed?(clsPath) 
      end
    end
    if(anyExposed)
      return true
    end

    if(!validSuperClasses.empty?)
      otherPartiallyExposedTypes.each do |cls|
        if(false)
          return canPartiallyExposeClass(cls, otherPartiallyExposedTypes)
        end
      end
    end

    return false
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