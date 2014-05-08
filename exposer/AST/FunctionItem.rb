require_relative "ArgumentItem.rb"

module AST
  
  # A function or member item.
  class FunctionItem < HierarchyItem

    # Create a function from a parent item, data from clang, and a bool is this is a constructor
    def initialize(parent, data, constructor) super(parent, data)
      @name = data[:name]
      @isConstructor = constructor
      @isConst = FunctionItem.isConstFunction(data[:cursor])
      @isOverride = data[:cursor].overriddens.length != 0
      @comment = data[:comment]
      @accessSpecifier = data[:cursor].access_specifier
      @static = parent.kind_of?(NamespaceItem) || data[:cursor].static?
      @arguments = []
      @returnType = data[:type].resultType
      @isVariadic = data[:cursor].variadic?
    end

    attr_reader :returnType, :arguments, :isConstructor, :isConst, :comment, :accessSpecifier, :static, :isOverride, :isVariadic

    def self.build(parent, data, isCtor)
      return AST::FunctionItem.new(parent, data, isCtor)
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
      param = AST::ArgumentItem.new(data, @arguments.length, self)
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

  private
    def self.isConstFunction(cursor)
      usr = cursor.usr
      idx = usr.rindex('#')

      if (idx == nil)
        return false
      end

      num = usr[idx+1].to_i

      # find usr, check for bit 1 in num after #
      return num & 1 == 1
    end
  end
end