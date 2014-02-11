# Library is a group of classes and settings which can be exposed as a group
class Library
  def initialize(name, path)
    @name = name
    @root = path
    @includePaths = []
    @files = []
    @dependencies = []
  end
  
  attr_reader :name, :files, :root, :dependencies
  
  # The path which should hold auto gen files for the library
  def autogenPath
    return "#{root}/autogen_#{name}"
  end

  # Add a source file path to the library
  def addFile(path)
    @files << path
  end
  
  # add a dependency library to this library
  def addDependency(dep)
    @dependencies << dep
  end
  
  # add an include path to the library
  def addIncludePath(path)
    @includePaths << path
  end

  # find an array of all the include paths this library requires, including its dependent library include paths.
  def includePaths
    localPaths = @includePaths.map{ |path| root + "/" + path + "/" }
    externalPaths = @dependencies.map{ |dep| dep.includePaths }.reduce([]) { |sum, obj| sum + obj }

    allPaths = (localPaths + externalPaths).uniq

    return allPaths
  end
end