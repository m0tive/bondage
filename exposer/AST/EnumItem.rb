require_relative "HierarchyItem.rb"

module AST
  
  # An enum item
  class EnumItem < AST::HierarchyItem
    # create a class from a parent item, clang data, and bools for struct/template-iness
    def initialize(parent, data) super(parent, data)
      @name = data[:name]
      @comment = data[:comment]
      @members = {}
    end

    attr_reader :name, :comment, :members

    def self.build(parent, data)
      return AST::EnumItem.new(parent, data)
    end

    def addEnumMember(data)
      @members[data[:name]] = data[:cursor].enum_value
    end
  end
end