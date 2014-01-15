
class ScopedObject

  def endScope
  end
  
end

class Visitor
  def beginNamespace(parent)
  end
  
  def beginClass(parent)
  end
  
  def beginFunction(parent)
  end
  
  def beginParameter(parent)
  end
  
  def beginTemplateParameter(parent)
  end
end
