require_relative "ClassExposer.rb"
require_relative "ParsedLibrary.rb"
require "json"

# A serialisable class which is exposed in a library.
# Allows querying data of types from other libraries, not parsed in the current operation.
#
class TypeData
  # Create a TypeData, given a short name and a parent, fully qualified path.
  # [parsed] is optional, and should only be supplied if it was parsed in this library.
  def initialize(name, parent, type, library, filename, parsed=nil)
    @name = name
    @type = type
    @fullyExposed = false
    @isDerivable = false
    @parsed = parsed
    @filename = filename
    @parentClass = parent
    @library = library
    @templateArgumentsToSatisfy = nil
  end

  attr_reader :name, 
              :type, 
              :filename,
              :fullyExposed,
              :parsed,
              :parentClass,
              :isDerivable,
              :library,
              :templateArgumentsToSatisfy

  # Set this class as fully exposed, a fully exposed
  # class can be used as both an input and output argument.
  def setFullyExposed()
    @fullyExposed = true
  end

  # Set this class as deriable, ie can have child classes.
  def setDerivable()
    @isDerivable = true
  end

  def setTemplateArgumentsToSatisfy(args)
    @templateArgumentsToSatisfy = args
  end

  # The parent class is supplied on construction, and worked out when creating all
  # class meta data (in the Meta Data Generator). The parent class is the first
  # inherited class which is also exposed.
  def hasParentClass
    return @parentClass != nil
  end

  # Serialise the TypeData to json, except the [@parsed].
  def to_json(opt)
    data = {
      :name => @name,
      :parent => @parentClass,
      :filename => @filename
    }
    
    if(@type != :class)
      data[:type] = @type
    end

    if(!@fullyExposed)
      data[:partial] = true
    end

    if(@isDerivable)
      data[:derivable] = true
    end

    if(@templateArgumentsToSatisfy)
      data[:templateArgumentsToSatisfy] = @templateArgumentsToSatisfy
    end
    return JSON.pretty_generate(data, opt)
  end

  # Create a TypeData from json, with a nil [@parsed]
  def self.from_json(data, library)
    type = :class
    if (data.has_key?("type"))
      type = data["type"]
    end

    filename = ""
    if (data.has_key?("filename"))
      filename = data["filename"]
    end

    cls = TypeData.new(data["name"], data["parent"], type, library, filename)
    if (!data.include?("partial"))
      cls.setFullyExposed()
    end

    if (data.include?("derivable"))
      cls.setDerivable()
    end

    templateArgs = data["templateArgumentsToSatisfy"]
    if (templateArgs)
      cls.setTemplateArgumentsToSatisfy(templateArgs)
    end

    return cls
  end
end

# TypeDataSet is a set of types which are exposed in some library(s).
# The data sets can be restored from disk, and merged to represent multiple libraries types.
class TypeDataSet
  # Create a class set from a hash of fully qualified path, to TypeData
  def initialize(types = {})
    @types = types
    @fullTypes = @types.select { |key, val| val.fullyExposed }
  end

  attr_reader :types, :fullTypes

  def debugTypes
    return types.keys
  end

  # Merge this set with another set.
  def merge(other)
    @types.merge!(other.types)
    @fullTypes.merge!(other.fullTypes)
  end

  # Find the class data for [clsPath] in this set, or nil.
  def findClass(clsPath)
    return types[clsPath]
  end

  # Is the class path passed fully exposed?
  def fullyExposed?(cls)
    return fullTypes.include?(cls)
  end

  # Is the class path passed partially exposed (ie contained at all in the set)?
  def partiallyExposed?(cls)
    return types.include?(cls)
  end

  def isExposedEnum?(enum)
    cls = findClass(enum)
    if (!cls)
      return false
    end

    return cls.type == :enum
  end

  def canDeriveFrom?(cls)
    type = types[cls]
    if (!type)
      return false
    end

    return type.isDerivable
  end

  # Find the class count for all complete types in the set.
  def fullClassCount
    return fullTypes.length
  end

  # Add a type to the meta data container
  def addType(full, type)
    types[full] = type
    if (type.fullyExposed)
      fullTypes[full] = type
    end
  end

  # Save this set into [dir], in json form
  def export(dir)
    raise "Invalid export directory '#{dir}'" unless File.directory?(dir)

    File.open(dir + "/types.json", 'w') do |file|
      file.write(JSON.pretty_generate(@types))
    end
  end

  # Load a set from [dir].
  def self.import(dir, library)
    types = JSON.parse(File.open("#{dir}/types.json", "r").read())

    outClasses = {}
    types.each do |ary|
      outClasses[ary[0]] = TypeData.from_json(ary[1], library)
    end

    return TypeDataSet.new(outClasses)
  end
end
