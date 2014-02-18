require_relative "ExposeAst.rb"
require_relative "ClassMetaData.rb"
require "set"

# Decides what classes and functions can be exposed, using data from the current parse, and dependency parses.
class Exposer
  # Create an exposed from a [visitor] derived class, which links to the library to expose
  def initialize(visitor, debug=false)
    @debugOutput = debug

    @allMetaData = ClassDataSet.new()
    mergeDependencyClasses(@allMetaData, visitor.library)

    exposedClasses = []
    partiallyExposedClasses = []
    parentClasses = {}

    visitor.classes.each do |cls|
      if(canExposeClass(cls, partiallyExposedClasses, parentClasses))
        exposedClasses << cls
        partiallyExposedClasses << cls
      elsif(canPartiallyExposeClass(cls, partiallyExposedClasses, parentClasses))
        partiallyExposedClasses << cls
      end
    end

    @exposedMetaData = ClassDataSet.fromClasses(exposedClasses, partiallyExposedClasses, parentClasses)
    @exposedMetaData.export(visitor.library.autogenPath)

    @allMetaData.merge(@exposedMetaData)
  end

  attr_reader :exposedMetaData, :allMetaData

  # find if a method [fn], a FunctionItem class can be exposed in the current library.
  def canExposeMethod(fn)
    if(fn.isExposed == nil)
      # methods must be public to expose
      canExpose = fn.accessSpecifier == :public
      # methods must have a partially exposed return type (it or a derived class)
      canExpose = canExpose && (fn.returnType == nil || canExposeType(fn.returnType, true))
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

    return canExposeType(obj.type, false)
  end

  def findExposedFunctions(cls)
    functions = {}

    # find all exposable functions as an array
    exposableFunctions = cls.functions.select{ |fn| canExposeMethod(fn) }

    # group these functions by overload
    exposableFunctions.each do |fn|
      if(functions[fn.name] == nil)
        functions[fn.name] = []
      end

      functions[fn.name] << fn
    end

    return functions
  end

private
  # Merge dependencies from [lib] (and its dependents), into [dataToMerge].
  def mergeDependencyClasses(dataToMerge, lib)
    lib.dependencies.each do |dep|
      mergeDependencyClasses(dataToMerge, dep)

      metaData = ClassDataSet.import(dep.autogenPath)
      dataToMerge.merge(metaData)
    end
  end

  # Find if [type], a Type class, can be exposed.
  def canExposeType(type, partialOk)
    # basic types can always be exposed
    if(type.isVoid() ||
       type.isBoolean() ||
       type.isStringLiteral() ||
       type.isInteger() ||
       type.isFloatingPoint())
      return true
    end

    # Pointer and reference types can be exposed if their pointed type can be exposed,
    # and they arent pointers to pointers.
    if(type.isPointer() || type.isLValueReference() || type.isRValueReference())
      pointed = type.pointeeType()
      if(pointed.isPointer())
        return false
      end

      return canExposeType(pointed, partialOk)
    end

    # otherwise, find the fully qualified type name, and find out if its exposed.
    name = type.name

    fullName = "::#{name}"

    if((partialOk && @allMetaData.partiallyExposed?(fullName)) ||
      @allMetaData.fullyExposed?(fullName))
      return true
    end

    return false
  end

  def findValidParentClasses(cls)
    validSuperClasses = Set.new

    # find valid super classes
    cls.superClasses.each do |cls|
      if(cls[:accessSpecifier] == :public)
        clsPath = "::#{cls[:type].name}"
        validSuperClasses << clsPath
      end
    end

    return validSuperClasses
  end

  # find if any classes in array [clss] are contained in array [activeExposedTypes]
  def findExposableClass(toExpose, clss, activeExposedTypes, parentClasses)

    # otherwise, search for a super class in the current library.
    if(!clss.empty?)
      activeExposedTypes.each do |cls|
        if(clss.include?(cls.fullyQualifiedName()))

          if(canExposeClass(cls, activeExposedTypes, parentClasses) || 
             canPartiallyExposeClass(cls, activeExposedTypes, parentClasses))

            parentClasses[toExpose.fullyQualifiedName()] = cls.fullyQualifiedName()
            return cls.fullyQualifiedName()
          end
        end
      end
    end

    return nil
  end

  def findParentClass(cls, otherPartiallyExposedTypes, parentClasses)
    cached = parentClasses[cls.fullyQualifiedName()]
    if(cached)
      return cached
    end

    validSuperClasses = findValidParentClasses(cls)

    # find valid super classes
    validSuperClasses.each do |clsPath|
      # if a super class is exposed in a parent library, then can partially expose the class.
      if(allMetaData.partiallyExposed?(clsPath))
        parentClasses[cls.fullyQualifiedName()] = clsPath
        return clsPath
      end
    end

    return findExposableClass(cls, validSuperClasses, otherPartiallyExposedTypes, parentClasses)
  end

  # find if a class can be partially exposed (ie, if one of its parent classes is exposed.)
  def canPartiallyExposeClass(cls, otherPartiallyExposedTypes, parentClasses)
    if(@allMetaData.partiallyExposed?(cls.fullyQualifiedName()))
      return false
    end
    
    # classes without super classes cannot be pushed at all.
    if(cls.superClasses.empty? or
      (cls.accessSpecifier != :invalid && cls.accessSpecifier != :public))
      return false
    end

    return findParentClass(cls, otherPartiallyExposedTypes, parentClasses) != nil
  end

  # find if a class can be exposed
  def canExposeClass(cls, otherPartiallyExposedTypes, parentClasses)
    if(cls.isExposed == nil)
      # exposed classes must opt in.
      hasExposeComment = cls.comment.hasCommand("expose")
      if(@debugOutput)
        puts "#{hasExposeComment ? "Y" : "N"}\t#{cls.name}"
      end

      if(!hasExposeComment)
        cls.setExposed(false)
        return false
      end

      if(@allMetaData.partiallyExposed?(cls.fullyQualifiedName()))
        return false
      end

      # check for parent classes (also updates parentClasses)
      findParentClass(cls, otherPartiallyExposedTypes, parentClasses)

      verifyAbleToExposeClass(cls)
      cls.setExposed(true)
    end

    return cls.isExposed
  end

  # classes must meet some requirements to be exposed, this method checks [cls meets these.]
  def verifyAbleToExposeClass(cls)
    # there are a few other enforcements to whether a class is exposed, template
    # classes and anonymous classes are banned, and private/protected
    #
    # these cases will raise errors if encountered, as someone has asked for an
    # exposure which cannot be provided.
    #
    willExpose =
      !cls.isTemplated &&
      !cls.name.empty? &&
      (cls.accessSpecifier == :public || cls.accessSpecifier == :invalid)

    if(!willExpose || @debugOutput)
      puts "\tExposeRequested: #{hasExposeComment}\tTemplate: #{cls.isTemplated}"
    end

    raise "Unable to expose requested class #{cls.name}" if not willExpose
    return willExpose
  end
end