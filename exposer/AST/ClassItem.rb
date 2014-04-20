require_relative "ClassableItem.rb"

module AST

  # A class item is an optionally templated class or struct.
  class ClassItem < AST::ClassableItem
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
      return AST::ClassItem.new(parent, data, struct, template)
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
      fn = AST::FunctionItem.build(self, data, true)
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
end