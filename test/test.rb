require_relative "../parser.rb"
require_relative "../library.rb"
require_relative "../visitor.rb"

class HierarchyItem
  def initialize(parent)
    @parent = parent
    @visitor = parent.visitor()
  end
  
  attr_reader :parent
  
  def visitor
    return @visitor
  end

  def fullyQualifiedName()
    if(@parent)
      return "#{@parent.fullyQualifiedName()}::#{self.name()}"
    else
      return "::#{self.name()}"
    end
  end

  def name()
    return ""
  end

  def children
    return []
  end
end

class ClassableItem < HierarchyItem
  def initialize(parent) super(parent)
    @classes = {}
  end

  attr_reader :classes

  def addStruct(data)
    cls = ClassItem.build(self, data, true, false)
    classes[data[:name]] = cls
    visitor().addDescendantClass(cls)
    return cls
  end
  
  def addClass(data)
    cls = ClassItem.build(self, data, false, false)
    classes[data[:name]] = cls
    visitor().addDescendantClass(cls)
    return cls
  end
  
  def addClassTemplate(data)
    cls = ClassItem.build(self, data, false, true)
    classes[data[:name]] = cls
    visitor().addDescendantClass(cls)
    return cls
  end
  
  def addUnion(data)
  end

  def children
    return classes
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
  def initialize(parent, data, struct, template) super(parent)
    @name = data[:name]
    @isStruct = struct
    @isTemplated = template
    @comment = data[:comment]
  end

  attr_reader :name, :isStruct, :isTemplated, :comment

  def self.build(parent, data, struct, template)
    return ClassItem.new(parent, data, struct, template)
  end

  def name()
    return @name
  end
  
  def addTemplateParam(data)
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
  def initialize(library, data) super(library)
    @namespaces = {}
    @name = data[:name]
  end

  attr_reader :name
  
  def self.build(parent, data)
    return NamespaceItem.new(parent, data)
  end

  def name()
    return @name
  end

  
  def addFunction(data)
    return FunctionItem.build(self, data)
  end
  
  def addFunctionTemplate(data)
  end
  
  def addNamespace(data)
    ns = @namespaces[data[:name]]
    if (!ns)
      ns = NamespaceItem.build(self, data)
    end

    return ns
  end

  def children
    return classes + super.children()
  end
  
end

class VisitorImpl < Visitor
  def initialize(library)
    @library = library
    
    @namespaces = {}
    @classes = []
  end

  attr_reader :namespaces, :classes

  def fullyQualifiedName()
    return ""
  end
  def visitor()
    return self 
  end
  
  def addNamespace(data)
    ns = @namespaces[data[:name]]
    
    if(!ns)
      ns = NamespaceItem.build(self, data)
      namespaces[data[:name]] = ns
    end
    
    return ns
  end

  def addDescendantClass(cls)
    @classes << cls
  end
end

class Exposer
  def initialize(library, debug)
    @debugOutput = debug
    @exposedClasses = library.classes.select do |cls| canExposeClass(cls) end
  end

  attr_reader :exposedClasses

private
  def canExposeClass(cls)
    hasExposeComment = cls.comment.hasCommand("expose")
    if(@debugOutput)
      puts "#{hasExposeComment}\t#{cls.name}"
    end

    if(!hasExposeComment)
      return false
    end

    willExpose = 
      !cls.isTemplated && 
      !cls.name.empty?

    if(!willExpose || @debugOutput)
      puts "\tExposeRequested: #{hasExposeComment}\tTemplate: #{cls.isTemplated}"
    end
    raise "Unable to expose requested class #{cls.name}" if not willExpose 
    return willExpose
  end

end

library = Library.new("Test", "test")
library.addIncludePath(".")
library.addFile("test.h")
library.addFile("test_2.h")

debugging = true

parser = Parser.new(library)

visitor = VisitorImpl.new(library)
parser.parse(visitor)

exposer = Exposer.new(visitor, debugging)

puts "Exposed Classes:"
puts exposer.exposedClasses.map { |cls| cls.fullyQualifiedName }
