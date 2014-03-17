require_relative "FunctionGenerator.rb"

# Generate exposures for classes
class ClassGenerator
  def initialize()
    reset()
  end

  attr_reader :interface, :implementation

  def reset()
    @interface = ""
    @implementation = ""
  end

  def generate(exposer, cls)
    @exposer = exposer
    @functions = exposer.findExposedFunctions(cls)

    @cls = cls
    @metaData = exposer.exposedMetaData.findClass(cls.fullyQualifiedName)

    generateHeader()
  end

private
  def generateHeader()

    clsPath = @cls.fullyQualifiedName
    if(!@metaData.hasParentClass())
      type = classMode()
      @interface = "#{MACRO_PREFIX}EXPOSED_CLASS_#{type}(#{clsPath})"
    else
      parent = @metaData.parentClass
      root = findRootClass(@metaData)
      @interface = "#{MACRO_PREFIX}EXPOSED_DERIVED_CLASS(#{clsPath}, #{parent}, #{root})"
    end
  end

  CLASS_MODES = [ :copyable, :managed, :unmanaged ]

  def classMode
    cmd = @cls.comment.command("expose")

    mode = :default
    defaultMode = :copyable
    CLASS_MODES.each do |possMode|
      str = possMode.to_s
      if (cmd.hasArg(str))
        raise "'Multiple class management modes specified #{mode.to_s} and '#{str}'." if mode != :default
        mode = possMode
      end
    end

    if (mode == :default)
      if (!@metaData.hasParentClass())
        mode = :copyable
      else
        mode = :managed
      end
    end

    raise "#{@cls.locationString}: A copyable class cannot be derivable." if @metaData.isDerivable && mode == :copyable

    return mode.to_s.upcase
  end

  def findRootClass(md)
    cls = md.parentClass
    while(!cls.empty?)
      parentName = @exposer.exposedMetaData.findClass(cls).parentClass
      if (!parentName)
        return cls
      end
      cls = parentName
    end

    return nil
  end
end