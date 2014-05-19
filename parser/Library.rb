# Library is a group of classes and settings which can be exposed as a group
class Library
  def initialize(name, path="", exportMacro=nil)
    @name = name
    @namespaceName = name
    @root = path
    @rootPathname = Pathname.new(@root)
    @includePaths = []
    @files = []
    @dependencies = []
    @languagesAutogenPath = { }
    @exportMacro = exportMacro ? exportMacro : name.upcase() + "_EXPORT"
    @coreInclude = "#{name}.h"
  end

  attr_reader :name, :files, :root
  attr_accessor :namespaceName, :rootPathname, :includePaths, :dependencies, :exportMacro, :coreInclude

  def setAutogenPath(lang, path)
    @languagesAutogenPath[lang] = path
  end

  # The path which should hold auto gen files for the library
  def autogenPath(lang)
    pth = @languagesAutogenPath[lang]
    if (pth)
      return pth
    end

    return "#{root}/autogen_#{name}"
  end

  def setRoot(root)
    @root = root
    @rootPathname = Pathname.new(@root)
  end

  # Add a source file path to the library
  def addFile(path)
    @files << path
  end

  # Add a source file path to the library
  def addFiles(path, pattern, recursive)
    pattern = "#{root}/#{path}/#{recursive ? "**/" : ""}#{pattern}"
    Dir.glob(pattern).each do |item|
      next if item == '.' or item == '..'
      # do work on real items

      filePath = Pathname.new(item).relative_path_from(@rootPathname)
      addFile(filePath)
    end
  end

  # add a dependency library to this library
  def addDependency(dep)
    @dependencies << dep
  end

  # add a dependency library to this library
  def addDependencies(depArr)
    @dependencies = @dependencies.concat(depArr)
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