require_relative "../parser.rb"
require_relative "../library.rb"
require_relative "../visitor.rb"

class HierarchyItem
  def initialize(parent)
    @parent = parent
  end
  
  attr_reader :parent
  
  def library
    while(@parent)
      if(@parent.kind_of?(Visitor))
        return @parent.library
      end
    end
  end
end

class ClassableItem < HierarchyItem
  def addStruct(data)
    return ClassItem.build(data, self)
  end
  
  def addClass(data)
    return ClassItem.build(data, self)
  end
  
  def addClassTemplate(data)
  end
  
  def addUnion(data)
  end
end

class EnumItem < HierarchyItem  
  def self.build(parent, data)
    return EnumItem.new(parent)
  end
  
  def addEnumMember(data)
  end
end

class FunctionItem < HierarchyItem  
  def self.build(parent, data)
    return FunctionItem.new(parent)
  end
  
  def addReturnType(data)
  end
  
  def addParam(data)
  end
end

class ClassItem < ClassableItem
  def self.build(parent, data)
    puts parent
    return ClassItem.new(parent)
  end
  
  def addConstructor(data)
  end
  
  def addDestructor(data)
  end
  
  def addFunction(data)
    return FunctionItem.build(self, data)
  end
  
  def addFunctionTemplate(data)
  end
  
  def addField(data)
  end
  
  def addAccessSpecifier(data)
  end
  
  def addEnum(data)
    return EnumItem.build(self, data)
  end
end

class NamespaceItem < ClassableItem
  def self.build(parent, data)
    #if(data[:name] == parent.library().name)
      return NamespaceItem.new(parent)
    #end
  end
  
  def addFunction(data)
    return FunctionItem.build(self, data)
  end
  
  def addFunctionTemplate(data)
  end
  
  def addNamespace(data)
    return NamespaceItem.build(self, data)
  end
  
end

class VisitorImpl < Visitor
  def initialize(library)
    @library = library
    
    @namespaces = {}
  end

  def library()
    return @library 
  end
  
  def addNamespace(data)
    ns = @namespaces[data[:name]] = ns
    
    if(!ns)
      ns = NamespaceItem.build(self, data)
    end
    
    return ns
  end

end 

library = Library.new("Test", "test")
library.addIncludePath(".")
library.addFile("test.h")
library.addFile("test_2.h")

parser = Parser.new(library)

visitor = VisitorImpl.new(library)
parser.parse(visitor)
