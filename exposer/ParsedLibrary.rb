# The expose AST is a hierarchy of classes produced from visiting the Clang AST.
# The expose AST groups data (and comments) in ways more useful when exposing later.
#
require_relative "AST/ArgumentItem.rb"
require_relative "AST/ClassableItem.rb"
require_relative "AST/ClassItem.rb"
require_relative "AST/EnumItem.rb"
require_relative "AST/FunctionItem.rb"
require_relative "AST/HierarchyItem.rb"
require_relative "AST/NamespaceItem.rb"

require_relative "../parser/Parser.rb"


# ExposeAstVisitor implements the Parsers Visitor interface
# and is the owner of a single parse operation
class ParsedLibrary
  # Create a visitor from a library
  def initialize(library, debug=false)
    @debugging = debug
    @library = library
    @rootItem = AST::NamespaceItem.new(self, { :name => "" })
    @classes = []
  end

  attr_reader :classes, :library, :rootItem

  def self.parse(library, platformIncludes=[], extraArgs=[], debug=false)
    parser = Parser.new(library, platformIncludes, extraArgs, debug)

    parsed = ParsedLibrary.new(library)
    parser.parse(parsed)

    if (debug)
      parser.displayDiagnostics
    end

    return parsed
  end

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
    ns = rootItem.namespaces[library.namespaceName]
    return ns
  end
end