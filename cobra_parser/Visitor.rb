# Visitor is the base class passed to the parser.
# it provides a way to access [rootItem], the global namespace.
class Visitor

  # find the global namespace for the visitor.
  def rootItem
    nil
  end
end
