require_relative "ClassableItem.rb"

module AST

  # A namespace
  class NamespaceItem < ClassableItem
    # create a namespace from a library and clang data
    def initialize(parent, data) super(parent, data)
      @namespaces = {}
      @name = data[:name]
    end

    attr_reader :name, :namespaces

    def self.build(parent, data)
      return AST::NamespaceItem.new(parent, data)
    end

    # add a namespace to the namespace
    def addNamespace(data)
      ns = @namespaces[data[:name]]
      if (!ns)
        ns = AST::NamespaceItem.build(self, data)
        @namespaces[data[:name]] = ns
      end

      return ns
    end
  end
end