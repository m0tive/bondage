# The expose AST is a hierarchy of classes produced from visiting the Clang AST.
# The expose AST groups data (and comments) in ways more useful when exposing later.
#

# A hierarchy item is the base class for objects sitting in the AST.
class HierarchyItem

  # Create a hierarchy item from a parent HierarchyItem (must have a .visitor function)
  def initialize(parent)
    @isExposed = nil
    @parent = parent
    @visitor = parent.visitor()
    @fullyQualified = nil
  end
  
  attr_reader :parent, :isExposed, :visitor
  
  # Set whether the item is exposed
  def setExposed(val)
    @isExposed = val
  end

  # Find the fully qualified path for this item (ie ::XXX::YYY::ZZZ)
  def fullyQualifiedName()
    # this is cached as we use it a lot
    if(@fullyQualified)
      return @fullyQualified
    end

    if(parent.kind_of?(Visitor))
      @fullyQualified = ""
    elsif(@parent)
      @fullyQualified = "#{@parent.fullyQualifiedName()}::#{self.name()}"
    else
      @fullyQualified = "::#{self.name()}"
    end

    return @fullyQualified
  end

  # Overridden name in derived classes.
  def name
    return ""
  end

  # Overridden children in derived classes.
  def children
    return []
  end
end

# A classable item can contain classes, structs and unions.
class ClassableItem < HierarchyItem
  def initialize(parent) super(parent)
    @classes = {}
  end

  attr_reader :classes

  # Add a struct to the container, [data] is a hash of data from clang
  def addStruct(data)
    cls = ClassItem.build(self, data, true, false)
    classes[data[:name]] = cls
    visitor().addDescendantClass(cls)
    return cls
  end
  
  # Add a class to the container, [data] is a hash of data from clang
  def addClass(data)
    cls = ClassItem.build(self, data, false, false)
    classes[data[:name]] = cls
    visitor().addDescendantClass(cls)
    return cls
  end
  
  # Add a template class to the container, [data] is a hash of data from clang
  def addClassTemplate(data)
    cls = ClassItem.build(self, data, false, true)
    classes[data[:name]] = cls
    visitor().addDescendantClass(cls)
    return cls
  end
  
  # Add a union to the container, [data] is a hash of data from clang
  def addUnion(data)
  end

  def children
    return classes
  end
end

# An enum item
class EnumItem < HierarchyItem  
  def self.build(parent, data)
    return EnumItem.new(parent)
  end
  
  def addEnumMember(data)
  end
end

class ArgumentItem
  def initialize(data, index, parent)
    @data = data
    @index = index
    @parent = parent

    comment = @parent.comment.paramforArgIndex(index)
    @input = true
    @output = false

    @brief = ""

    if(comment)
      @brief = comment.text

      if(comment.explicitDirection)
        if(comment.direction == :pass_direction_in)
          @input = true
          @output = false
        elsif(comment.direction == :pass_direction_out)
          @input = false
          @output = true
        elsif(comment.direction == :pass_direction_inout)
          @input = true
          @output = true
        end
      end
    end
  end

  attr_reader :index, :brief

  def name
    @data[:name]
  end

  def brief
    @brief
  end

  def input?
    @input
  end

  def output?
    @output
  end

  def type
    @data[:type]
  end
end

# A function or member item.
class FunctionItem < HierarchyItem

  # Create a function from a parent item, data from clang, and a bool is this is a constructor
  def initialize(parent, data, constructor) super(parent)
    @name = data[:name]
    @isConstructor = constructor
    @comment = data[:comment]
    @accessSpecifier = data[:cursor].access_specifier
    @static = data[:cursor].static?
    @arguments = []
    @returnType = data[:type].resultType
  end

  attr_reader :returnType, :arguments, :isConstructor, :comment, :accessSpecifier

  def self.build(parent, data, isCtor)
    return FunctionItem.new(parent, data, isCtor)
  end

  def name
    return @name
  end

  def returnBrief
    brief = comment.command("return")
    if(!brief)
      brief = comment.command("returns")
    end
    return brief ? brief : ""
  end
  
  # Add a function parameter.
  def addParam(data)
    @arguments << ArgumentItem.new(data, @arguments.length, self)
  end
end

# A class item is an optionally templated class or struct.
class ClassItem < ClassableItem
  # create a class from a parent item, clang data, and bools for struct/template-iness
  def initialize(parent, data, struct, template) super(parent)
    @name = data[:name]
    @isStruct = struct
    @isTemplated = template
    @comment = data[:comment]
    @accessSpecifier = data[:cursor].access_specifier
    @functions = []
    @superClasses = []
  end

  attr_reader :name, 
    :isStruct, 
    :isTemplated, 
    :comment, 
    :functions, 
    :superClasses, 
    :accessSpecifier

  def self.build(parent, data, struct, template)
    return ClassItem.new(parent, data, struct, template)
  end

  def name
    return @name
  end

  # Add a superclass for tis class
  def addSuperClass(data)
    @superClasses << data
  end
  
  # Add a template param for this class
  def addTemplateParam(data)
  end

  # Add a constructor for this class.
  def addConstructor(data)
    fn = FunctionItem.build(self, data, true)
    @functions << fn
    return fn
  end
  
  # Add a descructor for this class
  def addDestructor(data)
  end
  
  # add a function for this class
  def addFunction(data)
    fn = FunctionItem.build(self, data, false)
    functions << fn
    return fn
  end
  
  # add a function template to this class
  def addFunctionTemplate(data)
  end
  
  # add a member to the class
  def addField(data)
  end
  
  # add an access specifier to the class
  def addAccessSpecifier(data)
  end
  
  # add an enum to the class
  def addEnum(data)
    return EnumItem.build(self, data)
  end
end

# A namespace
class NamespaceItem < ClassableItem
  # create a namespace from a library and clang data
  def initialize(parent, name) super(parent)
    @namespaces = {}
    @name = name
  end
  
  def self.build(parent, data)
    return NamespaceItem.new(parent, data[:name])
  end

  def name()
    return @name
  end

  # Add a function to the namespace
  def addFunction(data)
    return FunctionItem.build(self, data, false)
  end
  
  # Add a function template to the namespace
  def addFunctionTemplate(data)
  end
  
  # add a namespace to the namespace
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

# VisitorImpl implements the Parsers Visitor interface
# and is the owner of a single parse operation
class VisitorImpl < Visitor
  # Create a visitor from a library
  def initialize(library)
    @library = library
    @rootItem = NamespaceItem.new(self, "")
    @classes = []
  end

  attr_reader :namespaces, :classes, :library, :rootItem

  def fullyQualifiedName
    return ""
  end

  # derived namespaces call this to find their visitor.
  def visitor
    return self 
  end

  def addDescendantClass(cls)
    @classes << cls
  end
end