
module AST

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
end