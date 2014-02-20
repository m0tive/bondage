require_relative "ExposeAst.rb"
require_relative "TypeMetaData.rb"
require_relative "TypeExposer.rb"
require_relative "FunctionExposer.rb"
require "set"

# Decides what classes and functions can be exposed, using data from the current parse, and dependency parses.
class Exposer
  # Create an exposed from a [visitor] derived class, which links to the library to expose
  def initialize(visitor, debug=false)
    @debugOutput = debug

    @allMetaData = TypeDataSet.new()
    mergeDependencyClasses(@allMetaData, visitor.library)

    exposedClasses = []
    partiallyExposedClasses = []
    parentClasses = {}

    enums = []

    visitor.classes.each do |cls|
      if(canExposeClass(cls, partiallyExposedClasses, parentClasses))
        exposedClasses << cls
        partiallyExposedClasses << cls
        gatherEnums(cls, enums)
      elsif(canPartiallyExposeClass(cls, partiallyExposedClasses, parentClasses))
        partiallyExposedClasses << cls
      end
    end

    # The visitor and library have a root namespace (normally the name of the library)
    # We also try to expose enums from here.
    rootNs = visitor.getExposedNamespace()
    if(rootNs)
      gatherEnums(rootNs, enums)
    end

    @exposedMetaData = TypeDataSet.fromClasses(
      exposedClasses,
      partiallyExposedClasses,
      parentClasses,
      enums)

    @exposedMetaData.export(visitor.library.autogenPath)

    @allMetaData.merge(@exposedMetaData)

    @typeExposer = TypeExposer.new(@allMetaData)
    @functionExposer = FunctionExposer.new(@typeExposer)
  end

  attr_reader :exposedMetaData, :allMetaData

  def findExposedFunctions(cls)
    functions = {}

    # find all exposable functions as an array
    exposableFunctions = cls.functions.select{ |fn| @functionExposer.canExposeMethod(fn) }

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
  # Find if an enum can be exposed.
  def canExposeEnum(enum)
    return enum.comment.hasCommand("expose")
  end

  # Find all enums on the classable type [classable].
  def gatherEnums(classable, enums)
    classable.enums.each do |name, enum|
      if(canExposeEnum(enum))
        enums << enum
      end
    end
  end

  # Merge dependencies from [lib] (and its dependents), into [dataToMerge].
  def mergeDependencyClasses(dataToMerge, lib)
    lib.dependencies.each do |dep|
      mergeDependencyClasses(dataToMerge, dep)

      metaData = TypeDataSet.import(dep.autogenPath)
      dataToMerge.merge(metaData)
    end
  end

  def findValidParentClasses(cls)
    validSuperClasses = Set.new

    # find valid super classes
    cls.superClasses.each do |cls|
      if(cls[:accessSpecifier] == :public)
        clsPath = cls[:type].fullyQualifiedName
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