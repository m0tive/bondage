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
    @exposedMetaData = TypeDataSet.new()

    visitor.classes.each do |cls|
      if(canExposeClass(cls))

        # check for parent classes (also updates parentClasses)
        superClass = findParentClass(cls)
        data = TypeData.new(cls.name, superClass, :class, cls)
        data.setFullyExposed()

        if (canDeriveFrom(cls, superClass))
          data.setDerivable()
        end

        @exposedMetaData.addType(cls.fullyQualifiedName, data)
        @allMetaData.addType(cls.fullyQualifiedName, data)

        gatherEnums(cls)
      else
        canExpose, superClass = canPartiallyExposeClass(cls)
        if (canExpose)

          data = TypeData.new(cls.name, superClass, :class, cls)

          if (canDeriveFrom(cls, superClass))
            data.setDerivable()
          end

          @exposedMetaData.addType(cls.fullyQualifiedName, data)
          @allMetaData.addType(cls.fullyQualifiedName, data)
        end
      end
    end

    # The visitor and library have a root namespace (normally the name of the library)
    # We also try to expose enums from here.
    rootNs = visitor.getExposedNamespace()
    if(rootNs)
      gatherEnums(rootNs)
    end

    @exposedMetaData.export(visitor.library.autogenPath)

    @typeExposer = TypeExposer.new(@allMetaData)
    @functionExposer = FunctionExposer.new(@typeExposer)
  end

  attr_reader :exposedMetaData, :allMetaData

  def findExposedFunctions(cls)
    functions = {}

    # find all exposable functions as an array
    exposableFunctions = cls.functions.select{ |fn| @functionExposer.canExposeMethod(cls, fn) }

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
  def gatherEnums(classable)
    enums = []
    classable.enums.each do |name, enum|
      if(canExposeEnum(enum))
        enums << enum
      end
    end

    enums.each do |enum|
      data = TypeData.new(enum.name, nil, :enum, enum)
      data.setFullyExposed()

      @exposedMetaData.addType(enum.fullyQualifiedName, data)
      @allMetaData.addType(enum.fullyQualifiedName, data)
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

  def canDeriveFrom(cls, parent)
    # if the parent is derivable, this must be!
    if (parent != nil)
      return true
    end

    # with no parent and no expose, it cannot be derived from!
    cmd = cls.comment.command("expose")
    if (!cmd)
      return false
    end

    hasFlag = cmd.hasArg("derivable")
    return hasFlag 
  end

  def findParentClass(cls)
    validSuperClasses = findValidParentClasses(cls)


    # find valid super classes
    validSuperClasses.each do |clsPath|
      # if a super class is exposed in a parent library, then can partially expose the class.
      if(@allMetaData.canDeriveFrom?(clsPath))
        return clsPath
      end
    end

    return nil
  end

  # find if a class can be partially exposed (ie, if one of its parent classes is exposed.)
  def canPartiallyExposeClass(cls)
    hasNoExposeComment = cls.comment.hasCommand("noexpose")
    if (hasNoExposeComment)
      if(@debugOutput)
        puts "N\t#{cls.name} (requested not to)"
      end
      
      return false
    end

    if(@allMetaData.partiallyExposed?(cls.fullyQualifiedName()))
      if(@debugOutput)
        puts "N\t#{cls.name} (already exposed)"
      end

      return false
    end
    
    # classes without super classes cannot be pushed at all.
    if(cls.superClasses.empty? or
      (cls.accessSpecifier != :invalid && cls.accessSpecifier != :public))
      if(@debugOutput)
        puts "N\t#{cls.name} (not public)"
      end

      return false
    end

    parent = findParentClass(cls)
    if(@debugOutput)
      puts "#{parent != nil ? "Y" : "N"}\t#{cls.name} (no parent)"
    end
    return parent != nil, parent
  end

  # find if a class can be exposed
  def canExposeClass(cls)
    if(cls.isExposed == nil)
      # exposed classes must opt in.
      hasExposeComment = cls.comment.hasCommand("expose")
      hasNoExposeComment = cls.comment.hasCommand("noexpose")
      if (hasNoExposeComment)
        if(@debugOutput)
          puts "N\t#{cls.name} (requested not to)"
        end

        raise "Exposed and not exposed class #{cls.fullyQualifiedName}" if hasExposeComment
        return false
      end

      if (!hasExposeComment)
        cls.setExposed(false)
        if(@debugOutput)
          puts "N\t#{cls.name} (not requested)"
        end

        return false
      end

      if(@allMetaData.partiallyExposed?(cls.fullyQualifiedName()))
        if(@debugOutput)
          puts "N\t#{cls.name} (already exposed)"
        end
        return false
      end

      if(@debugOutput)
        puts "#{hasExposeComment ? "Y" : "N"}\t#{cls.name}"
      end
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

    raise "Unable to expose requested class #{cls.name}" if not willExpose
    return willExpose
  end
end