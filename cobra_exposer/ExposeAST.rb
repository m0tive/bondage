
class HierarchyItem
  def initialize(parent)
    @isExposed = nil
    @parent = parent
    @visitor = parent.visitor()
    @fullyQualified = nil
  end
  
  attr_reader :parent, :isExposed
  
  def setExposed(val)
    @isExposed = val
  end

  def visitor
    return @visitor
  end

  def fullyQualifiedName()
    if(@fullyQualified)
      return @fullyQualified
    end

    if(@parent)
      @fullyQualified = "#{@parent.fullyQualifiedName()}::#{self.name()}"
    else
      @fullyQualified = "::#{self.name()}"
    end

    return @fullyQualified
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
  def initialize(parent, data, constructor) super(parent)
    @name = data[:name]
    @isConstructor = constructor
    @comment = data[:comment]
    @returnType = nil
    @arguments = []
  end

  attr_reader :returnType, :arguments, :isConstructor

  def self.build(parent, data, isCtor)
    return FunctionItem.new(parent, data, isCtor)
  end

  def name
    return @name
  end
  
  def addReturnType(data)
    @returnType = data
  end
  
  def addParam(data)
    @arguments << data
  end
end

class ClassItem < ClassableItem
  def initialize(parent, data, struct, template) super(parent)
    @name = data[:name]
    @isStruct = struct
    @isTemplated = template
    @comment = data[:comment]
    @functions = []
  end

  attr_reader :name, :isStruct, :isTemplated, :comment, :functions

  def self.build(parent, data, struct, template)
    return ClassItem.new(parent, data, struct, template)
  end

  def name()
    return @name
  end
  
  def addTemplateParam(data)
  end

  def addConstructor(data)
    fn = FunctionItem.build(self, data, true)
    @functions << fn
    return fn
  end
  
  def addDestructor(data)
  end
  
  def addFunction(data)
    fn = FunctionItem.build(self, data, false)
    functions << fn
    return fn
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
    return FunctionItem.build(self, data, false)
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