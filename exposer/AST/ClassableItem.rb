require_relative "HierarchyItem.rb"
require_relative "FunctionItem.rb"

module AST

  # A classable item can contain classes, structs and unions.
  class ClassableItem < AST::HierarchyItem
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
        cls = AST::ClassItem.build(self, data, true, false)
        @classes[data[:name]] = cls
        visitor().addDescendantClass(cls)
      end
      return cls
    end

    # Add a class to the container, [data] is a hash of data from clang
    def addClass(data)
      cls = @classes[data[:name]]
      if (!cls)
        cls = AST::ClassItem.build(self, data, false, false)
        @classes[data[:name]] = cls
        visitor().addDescendantClass(cls)
      end
      return cls
    end

    # Add a template class to the container, [data] is a hash of data from clang
    def addClassTemplate(data)
      cls = @classes[data[:name]]
      if (!cls)
        cls = AST::ClassItem.build(self, data, false, true)
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
      fn = AST::FunctionItem.build(self, data, false)
      functions << fn
      return fn
    end

    # add a function template to this class
    def addFunctionTemplate(data)
    end

    # add an enum to the class
    def addEnum(data)
      enu = AST::EnumItem.build(self, data)
      @enums[data[:name]] = enu
      return enu
    end

    def children
      return @classes + @enums
    end
  end
end