require_relative "../parser/Visitor.rb"
# The expose AST is a hierarchy of classes produced from visiting the Clang AST.
# The expose AST groups data (and comments) in ways more useful when exposing later.
#

# A hierarchy item is the base class for objects sitting in the AST.
class HierarchyItem

  # Create a hierarchy item from a parent HierarchyItem (must have a .visitor function)
  def initialize(parent, data)
    @isExposed = nil
    @cursor = data[:cursor]
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
  def fullyQualifiedName
    # this is cached as we use it a lot
    if(@fullyQualified)
      return @fullyQualified
    end

    if(@parent && !parent.kind_of?(Visitor))
      @fullyQualified = "#{@parent.fullyQualifiedName()}::#{self.name()}"
    else
      @fullyQualified = ""
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

  def locationString
    return sourceError(@cursor)
  end

  def fileLocation
    return @cursor.location.file
  end
end

# A classable item can contain classes, structs and unions.
class ClassableItem < HierarchyItem
  def initialize(parent, data) super(parent, data)
    @classes = {}
    @enums = {}
    @functions = []
  end

  attr_reader :classes, :enums, :functions

  # Add a struct to the container, [data] is a hash of data from clang
  def addStruct(data)
    cls = @classes[data[:name]]
    if (!cls)
      cls = ClassItem.build(self, data, true, false)
      @classes[data[:name]] = cls
      visitor().addDescendantClass(cls)
    end
    return cls
  end

  # Add a class to the container, [data] is a hash of data from clang
  def addClass(data)
    cls = @classes[data[:name]]
    if (!cls)
      cls = ClassItem.build(self, data, false, false)
      @classes[data[:name]] = cls
      visitor().addDescendantClass(cls)
    end
    return cls
  end

  # Add a template class to the container, [data] is a hash of data from clang
  def addClassTemplate(data)
    cls = @classes[data[:name]]
    if (!cls)
      cls = ClassItem.build(self, data, false, true)
      @classes[data[:name]] = cls
      visitor().addDescendantClass(cls)
    end
    return cls
  end

  # Add a union to the container, [data] is a hash of data from clang
  def addUnion(data)
  end

  # Add a typedef to the container, [data] is a hash of data from clang
  def addTypedef(data)
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

  # add an enum to the class
  def addEnum(data)
    enu = EnumItem.build(self, data)
    @enums[data[:name]] = enu
    return enu
  end

  def children
    return @classes + @enums
  end
end

# An enum item
class EnumItem < HierarchyItem
  # create a class from a parent item, clang data, and bools for struct/template-iness
  def initialize(parent, data) super(parent, data)
    @name = data[:name]
    @comment = data[:comment]
    @members = {}
  end

  attr_reader :name, :comment, :members

  def self.build(parent, data)
    return EnumItem.new(parent, data)
  end

  def addEnumMember(data)
    @members[data[:name]] = data[:cursor].enum_value
  end
end

class ArgumentItem
  def initialize(data, index, parent)
    @data = data
    @index = index
    @parent = parent
    @hasDefault = false

    setComment(@parent.comment.paramforArgIndex(index))
  end

  attr_reader :index, :brief, :hasDefault

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

  def addParamDefault(data)
    @hasDefault = true
    return nil
  end

private
  def setComment(comment)
    @input = true
    @output = false

    @brief = ""
    if (comment)
      @brief = comment.text

      if (comment.explicitDirection)
        case comment.direction
        when :pass_direction_in
          @input = true
          @output = false
        when :pass_direction_out
          @input = false
          @output = true
        when :pass_direction_inout
          @input = true
          @output = true
        end
      end
    end
  end
end

# A function or member item.
class FunctionItem < HierarchyItem

  # Create a function from a parent item, data from clang, and a bool is this is a constructor
  def initialize(parent, data, constructor) super(parent, data)
    @name = data[:name]
    @isConstructor = constructor
    @isOverride = data[:cursor].overriddens.length != 0
    @comment = data[:comment]
    @accessSpecifier = data[:cursor].access_specifier
    @static = parent.kind_of?(NamespaceItem) || data[:cursor].static?
    @arguments = []
    @returnType = data[:type].resultType
  end

  attr_reader :returnType, :arguments, :isConstructor, :comment, :accessSpecifier, :static, :isOverride

  def self.build(parent, data, isCtor)
    return FunctionItem.new(parent, data, isCtor)
  end

  def name
    return @name
  end

  def returnBrief
    brief = comment.commandText("return")
    if(!brief)
      brief = comment.commandText("returns")
    end
    return brief ? brief : ""
  end

  # Add a function parameter.
  def addParam(data)
    param = ArgumentItem.new(data, @arguments.length, self)
    @arguments << param
    return param
  end

  def isCopyConstructor
    if (!isConstructor)
      return false
    end

    if (arguments.length != 1)
      return false
    end


    type = arguments[0].type

    return type.isLValueReference() &&
           type.pointeeType.isConstQualified() &&
           type.pointeeType.shortName() == name()
  end
end

# A class item is an optionally templated class or struct.
class ClassItem < ClassableItem
  # create a class from a parent item, clang data, and bools for struct/template-iness
  def initialize(parent, data, struct, template) super(parent, data)
    @name = data[:name]
    @isStruct = struct
    @isTemplated = template
    @comment = data[:comment]
    @accessSpecifier = data[:cursor].access_specifier
    @superClasses = []
  end

  attr_reader :name,
    :isStruct,
    :isTemplated,
    :comment,
    :superClasses,
    :accessSpecifier

  def self.build(parent, data, struct, template)
    return ClassItem.new(parent, data, struct, template)
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

  # add a member to the class
  def addField(data)
  end

  # add an access specifier to the class
  def addAccessSpecifier(data)
  end
end

# A namespace
class NamespaceItem < ClassableItem
  # create a namespace from a library and clang data
  def initialize(parent, data) super(parent, data)
    @namespaces = {}
    @name = data[:name]
  end

  attr_reader :name, :namespaces

  def self.build(parent, data)
    return NamespaceItem.new(parent, data)
  end

  # add a namespace to the namespace
  def addNamespace(data)
    ns = @namespaces[data[:name]]
    if (!ns)
      ns = NamespaceItem.build(self, data)
      @namespaces[data[:name]] = ns
    end

    return ns
  end
end

# ExposeAstVisitor implements the Parsers Visitor interface
# and is the owner of a single parse operation
class ExposeAstVisitor < Visitor
  # Create a visitor from a library
  def initialize(library)
    @library = library
    @rootItem = NamespaceItem.new(self, { :name => "" })
    @classes = []
  end

  attr_reader :classes, :library, :rootItem

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

  def getExposedNamespace
    ns = rootItem.namespaces[library.name]
    return ns
  end
end