
class Library
  def initialize(name, path)
    @name = name
    @root = path
    @includePaths = []
    @files = []
    @dependencies = []
  end
  
  attr_reader :name, :files, :root, :dependencies
  
  def autogenPath
    return "#{root}/autogen_#{name}"
  end

  def addFile(path)
    @files << path
  end
  
  def addDependency(dep)
    @dependencies << dep
  end
  
  def addIncludePath(path)
    @includePaths << path
  end

  def includePaths
    localPaths = @includePaths.map{ |path| root + "/" + path + "/" }
    externalPaths = @dependencies.map{ |dep| dep.includePaths }.reduce([]) { |sum, obj| sum + obj }

    allPaths = (localPaths + externalPaths).uniq

    return allPaths
  end
end