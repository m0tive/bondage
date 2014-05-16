require_relative "ParsedLibrary.rb"
require_relative "TypeMetaData.rb"
require_relative "TypeExposer.rb"
require_relative "FunctionExposer.rb"
require "set"

# Decides what classes and functions can be exposed, using data from the current parse, and dependency parses.
class ClassExposer
  # Create an exposed from a [visitor] derived class, which links to the library to expose
  def initialize(visitor, debug=false)
    @debugOutput = debug

    @allMetaData = TypeDataSet.new()
    mergeDependencyClasses(@allMetaData, visitor.library)
    @exposedMetaData = TypeDataSet.new()

    gatherClasses(visitor)

    # The visitor and library have a root namespace (normally the name of the library)
    # We also try to expose enums from here.
    rootNs = visitor.getExposedNamespace()
    if(rootNs)
      gatherEnums(rootNs, visitor.library)
    end

    @exposedMetaData.export(visitor.library.autogenPath)

    @typeExposer = TypeExposer.new(@allMetaData)
    @functionExposer = FunctionExposer.new(@typeExposer, debug)
  end

  attr_reader :exposedMetaData, :allMetaData, :functionExposer

  def findExposedFunctions(cls)
    functions = {}

    if (@debugOutput)
      puts "Gathering exposable functions from #{cls.name} with #{cls.functions.length} functions"
    end

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
  
private
  # Find if an enum can be exposed.
  def canExposeEnum(enum)
    return enum.comment.hasCommand("expose")
  end

  # Find all enums on the classable type [classable].
  def gatherEnums(classable, lib)
    enums = []
    classable.enums.each do |name, enum|
      if(canExposeEnum(enum))
        enums << enum
      end
    end

    enums.each do |enum|
      data = createTypeData(enum, nil, :enum, lib, enum.fileLocation)
      data.setFullyExposed()

      @exposedMetaData.addType(enum.fullyQualifiedName, data)
      @allMetaData.addType(enum.fullyQualifiedName, data)
    end
  end

  # Merge dependencies from [lib] (and its dependents), into [dataToMerge].
  def mergeDependencyClasses(dataToMerge, lib)
    lib.dependencies.each do |dep|
      mergeDependencyClasses(dataToMerge, dep)

      metaData = TypeDataSet.import(dep.autogenPath, dep)
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

  # find if a class can be partially exposed (ie, if one of its parent classes is exposed.)
  def canPartiallyExposeClass(cls)
    hasNoExposeComment = cls.comment.hasCommand("noexpose")
    if (hasNoExposeComment)
      return exposeMsg(:no, cls, "requested not to")
    end

    if (@allMetaData.partiallyExposed?(cls.fullyQualifiedName()))
      return exposeMsg(:no, cls, "already exposed")
    end
    
    # classes without super classes cannot be pushed at all.
    if (!isAccessible(cls))
      return exposeMsg(:no, cls, "not public")
    end

    if (cls.superClasses.empty?)
      return exposeMsg(:no, cls, "no parent classes")
    end

    parent = findParentClass(cls)
    if (parent == nil)
      return exposeMsg(:no, cls, "no derivable parent")
    end

    exposeMsg(:partial, cls, "yes")
    return true, parent
  end

  # find if a class can be exposed
  def canExposeClass(cls)
    if(cls.isExposed == nil)
      cls.setExposed(calculateExposed(cls))
    end

    return cls.isExposed
  end

  def calculateExposed(cls)
    # exposed classes must opt in.
    hasExposeComment = cls.comment.hasCommand("expose")
    hasNoExposeComment = cls.comment.hasCommand("noexpose")

    if (hasNoExposeComment)
      raise "Exposed and not exposed class #{cls.fullyQualifiedName}" if hasExposeComment

      return exposeMsg(:no, cls, "requested not to")
    end

    if (!hasExposeComment)
      return exposeMsg(:no, cls, "not requested")
    end

    if(@allMetaData.partiallyExposed?(cls.fullyQualifiedName()))
      return exposeMsg(:no, cls, "already exposed")
    end

    exposeMsg(:yes, cls, "yes")

    verifyAbleToExposeClass(cls)
    return true
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
      isAccessible(cls)

    raise "Unable to expose requested class #{cls.name}" if not willExpose
    return willExpose
  end

  def gatherClasses(visitor)
    classes = sortClasses(visitor.classes)

    # sort classes by inheritance

    classes.each do |cls|
      if(canExposeClass(cls))
        addExposedClass(visitor, cls)
      else
        addPartiallyExposedClass(visitor, cls)
      end
    end
  end

  def sortClasses(classes)
    parentMap = { }

    classes.each do |cls|
      parentMap[cls.fullyQualifiedName] = {
        :data => cls,
        :parents => findValidParentClasses(cls),
        :children => [],
        :visited => false
      }
    end

    parentMap.each do |clsPath, data|
      data[:parents].each do |parent|
        parentData = parentMap[parent]
        if (parentData)
          parentData[:children] << clsPath
        end
      end
    end

    list = []

    def append(list, parentMap, id)
      data = parentMap[id]
      if (data[:visited])
        return
      end

      data[:children].each do |child|
        append(list, parentMap, child)
      end

      data[:visited] = true
      list << data[:data]
    end

    parentMap.keys.each do |clsPath|
      append(list, parentMap, clsPath)
    end

    return list.reverse
  end

  def addExposedClass(visitor, cls)
    # check for parent classes (also updates parentClasses)
    superClass = findParentClass(cls)
    data = createTypeData(cls, superClass, :class, visitor.library, cls.primaryFile)
    data.setFullyExposed()

    if (canDeriveFrom(cls, superClass))
      data.setDerivable()
    end

    @exposedMetaData.addType(cls.fullyQualifiedName, data)
    @allMetaData.addType(cls.fullyQualifiedName, data)

    gatherEnums(cls, visitor.library)
  end

  def addPartiallyExposedClass(visitor, cls)
    canExpose, superClass = canPartiallyExposeClass(cls)
    if (canExpose)

      data = createTypeData(cls, superClass, :class, visitor.library, cls.primaryFile)

      if (canDeriveFrom(cls, superClass))
        data.setDerivable()
      end

      @exposedMetaData.addType(cls.fullyQualifiedName, data)
      @allMetaData.addType(cls.fullyQualifiedName, data)
    end
  end

  def isAccessible(cls)
    return cls.accessSpecifier == :invalid || cls.accessSpecifier == :public
  end

  def exposeMsg(result, cls, msg)
    if (@debugOutput)
      res = result == :yes ? 'Y' :
            result == :partial ? 'Y p' : 
            'N'

      puts "#{result ? 'Y' : 'N'}\t#{cls.name} (#{msg})"
    end

    return result == :no ? false : true
  end

  def createTypeData(obj, superClass, type, lib, file)
    relativeFile = Pathname.new(file).relative_path_from(lib.rootPathname).to_s
    return TypeData.new(obj.name, superClass, type, lib, relativeFile, obj)
  end

end