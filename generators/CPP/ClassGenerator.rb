require_relative "FunctionGenerator.rb"

module CPP

  # Generate exposures for classes
  class ClassGenerator
    def initialize()
      reset()
    end

    attr_reader :interface, :implementation, :wrapperName

    def reset()
      @interface = ""
      @implementation = ""
      @wrapperName = ""

      @fnGen = CPP::FunctionGenerator.new("", "  ")
    end

    def generate(exposer, md, libraryVariable, files)
      @metaData = md
      @cls = md.parsed

      raise "Unparsed classes can not be exposed #{md.name}" unless @cls && @metaData

      @exposer = exposer

      if md.fullyExposed
        generateHeader()
        generateSource(libraryVariable, files)
      else
        generatePartial()
      end
    end

    def findRootClass(md)
      distance = 0
      cls = md.parentClass
      while(!cls.empty?)
        foundClass = @exposer.allMetaData.findClass(cls)
        raise "Failed to locate exposed class #{cls} in exposer #{@exposer.allMetaData.debugTypes}" unless foundClass

        parentName = foundClass.parentClass
        distance += 1
        if (!parentName)
          return cls, distance
        end
        cls = parentName
      end

      return nil, distance
    end

  private
    def generatePartial()
      clsPath = @cls.fullyQualifiedName
      raise "partial class without parent #{clsPath}" unless @metaData.hasParentClass()

      parent = @metaData.parentClass
      root, dist = findRootClass(@metaData)
      @interface = "#{MACRO_PREFIX}EXPOSED_DERIVED_PARTIAL_CLASS(#{@metaData.library.exportMacro}, #{clsPath}, #{parent}, #{root})"
    end

    def generateHeader()
      clsPath = @cls.fullyQualifiedName
      type = classMode()
      if(!@metaData.hasParentClass())
        derivable = ""
        if (@metaData.isDerivable)
          derivable = "DERIVABLE_"
        end
        @interface = "#{MACRO_PREFIX}EXPOSED_CLASS_#{derivable}#{type}(#{@metaData.library.exportMacro}, #{clsPath})"
      else
        parent = @metaData.parentClass
        root, dist = findRootClass(@metaData)
        @interface = "#{MACRO_PREFIX}EXPOSED_CLASS_DERIVED_#{type}(#{@metaData.library.exportMacro}, #{clsPath}, #{parent}, #{root})"
      end
    end

    # Generate binding data for a class
    def generateSource(libraryVariable, files)
      # find a name that is a valid literal in c++ used for static definitions
      fullyQualified = @cls.fullyQualifiedName()
      @wrapperName = fullyQualified.sub("::", "").gsub("::", "_")

      methods, extraMethods, typedefs = @fnGen.gatherFunctions(@cls, @exposer, files)

      methodsLiteral, methodsArray, extraMethodSource = @fnGen.generateFunctionArray(typedefs, methods, extraMethods, @wrapperName)

      parent = @metaData.parentClass

      classInfo =
"#{MACRO_PREFIX}IMPLEMENT_EXPOSED_CLASS(
  #{wrapperName},
  #{libraryVariable},
  #{@cls.parent.fullyQualifiedName()},
  #{@cls.name},
  #{parent ? parent : "void"},
  #{methodsLiteral},
  #{methods.length});"


      @implementation =
"// Exposing class #{fullyQualified}#{extraMethodSource}#{methodsArray}
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

      if (@cls.hasPureVirtualFunctions && mode == :copyable)
        raise "Abstract class #{@cls.name} can not be copyable"
      end

      return mode.to_s.upcase
    end
  end
end