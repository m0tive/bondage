require_relative "ExposeAST.rb"
require_relative "ClassMetaData.rb"
require "set"

class Exposer
  def initialize(visitor, debug)
    @debugOutput = debug
    
    @allMetaData = MetaDataGenerator.new()
    mergeDependencyClasses(@allMetaData, visitor.library)

    exposedClasses = []
    partiallyExposedClasses = []

    visitor.classes.each do |cls|
      if(canExposeClass(cls))
        exposedClasses << cls
        partiallyExposedClasses << cls
      elsif(canPartiallyExposeClass(cls, partiallyExposedClasses))
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
      puts fn.accessSpecifier
      canExpose = fn.accessSpecifier == :public
      canExpose = canExpose && (fn.returnType == nil || canExposeTypeImpl(fn.returnType))

      canExpose = canExpose && fn.arguments.all?{ |param| canExposeType(param) }

      fn.setExposed(canExpose)
      puts "Can expose #{fn.isExposed ? "Y" : "N"} #{fn.name}"
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

    return false
  end

  def canPartiallyExposeClass(cls, otherPartiallyExposedTypes)
    # exposed classes are also partially exposed
    if(canExposeClass(cls))
      return true
    end

    # classes without super classes cannot be pushed at all.
    if(cls.superClasses.empty? or cls.accessSpecifier != :public)
      return false
    end

    validSuperClasses = Set.new

    cls.superClasses.each do |cls|
      if(cls[:accessSpecifier] == :public)
        clsPath = "::#{cls[:type].name}"
        validSuperClasses << clsPath
        if(allMetaData.partiallyExposed?(clsPath))
          return true
        end
      end
    end

    if(!validSuperClasses.empty?)
      puts validSuperClasses.to_a
      otherPartiallyExposedTypes.each do |cls|
        if(validSuperClasses.include?(cls.fullyQualifiedName))
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

      if(!hasExposeComment )
        cls.setExposed(false)
        return false
      end

      willExpose = 
        !cls.isTemplated && 
        !cls.name.empty? && 
        (cls.accessSpecifier == :public || cls.accessSpecifier == :invalid)

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