
class Library
  def initialize(name, path)
    @name = name
    @root = path
    @includePaths = []
    @files = []
  end
  
  attr_reader :name, :files, :includePaths, :root
  
  def addFile(path)
    @files << path
  end
  
  
  def addIncludePath(path)
    @includePaths << path
  end
end