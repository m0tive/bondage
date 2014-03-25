require_relative "FunctionGenerator.rb"

module CPP

  # Generate exposures for classes
  class ClassGenerator
    def initialize()
      reset()
    end

    attr_reader :interface, :implementation

    def reset()
      @interface = ""
      @implementation = ""

      @fnGen = CPP::FunctionGenerator.new("", "  ")
    end

    def generate(exposer, md, libraryVariable)
      @metaData = md
      @cls = md.parsed

      raise "Unparsed classes can not be exposed #{md.name}" unless @cls && @metaData

      @exposer = exposer
      @functions = exposer.findExposedFunctions(@cls)

      generateHeader()
      generateSource(libraryVariable)
    end

  private
    def generateHeader()
      clsPath = @cls.fullyQualifiedName
      if(!@metaData.hasParentClass())
        type = classMode()
        derivable = ""
        if (@metaData.isDerivable)
        derivable = "DERIVABLE_"
        end
        @interface = "#{MACRO_PREFIX}EXPOSED_CLASS_#{derivable}#{type}(#{clsPath})"
      else
        parent = @metaData.parentClass
        root = findRootClass(@metaData)
        @interface = "#{MACRO_PREFIX}EXPOSED_DERIVED_CLASS(#{clsPath}, #{parent}, #{root})"
      end
    end

    # Generate binding data for a class
    def generateSource(libraryVariable)
      # find a name that is a valid literal in c++ used for static definitions
      fullyQualified = @cls.fullyQualifiedName()
      literalName = fullyQualified.sub("::", "").gsub("::", "_")

      methodsLiteral = literalName + "_methods";


      classInfo =
"#{MACRO_PREFIX}IMPLEMENT_EXPOSED_CLASS(
  #{libraryVariable},
  #{@cls.parent.fullyQualifiedName()},
  #{@cls.name},
  #{methodsLiteral});"

      functions = @exposer.findExposedFunctions(@cls)

      methods = []
      extraMethods = []

      # for each function, work out how best to call it.
      functions.sort.each do |name, fns|
        @fnGen.generate(@cls, fns)

        methods << @fnGen.bind
        extraMethods = extraMethods.concat(@fnGen.extraFunctions)
      end

      methodsSource = ""
      if (methods.length > 0)
        methodsSource = "  " + methods.join(",\n  ")
      end
      extraMethodSource = ""
      if (extraMethods.length > 0)
        extraMethodSource = "\n" + extraMethods.join("\n\n") + "\n"
      end

      @implementation =
"// Exposing class #{fullyQualified}
#{extraMethodSource}
const #{TYPE_NAMESPACE}::Function #{methodsLiteral}[] = {\n#{methodsSource}\n};

#{classInfo}
"
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
end