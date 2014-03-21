require_relative "../../exposer/ExposeAst.rb"
require_relative "../GeneratorHelper.rb"
require_relative "../../exposer/FunctionVisitor.rb"

require_relative "FunctionGenerator.rb"
require_relative "ClassGenerator.rb"

require 'pathname'

module CPP

  class LibraryGenerator
    def initialize()
      @header = ""
      @source = ""
    end

    attr_reader :header, :source

    def headerPath(library)
      return "#{library.autogenPath}/#{library.name}.h"
    end

    def sourcePath(library)
      return "#{library.autogenPath}/#{library.name}.cpp"
    end

    def generate(library, exposer)
      setLibrary(library)

      @header = filePreamble("//") + "\n\n" 
      @source = filePreamble("//") + "\n"
      @source += generateInclude(headerPath(library))
      sourcefiles = [ TYPE_NAMESPACE + "/RuntimeHelpersImpl.h", "utility", "tuple" ]

      library.dependencies.each{ |l| sourcefiles << headerPath(l) }

      @source += "\n" + sourcefiles.map{ |f| "#include \"#{f}\"" }.join("\n") + "\n\n\n"

      clsGen = ClassGenerator.new

      files = Set.new

      libraryName = "g_bondage_library";

      classHeader = ""
      classSource = ""

      exposer.exposedMetaData.types.each do |path, cls|
        if (cls.type == :class && cls.fullyExposed)
          clsGen.reset()
          clsGen.generate(exposer, cls, libraryName)
          classHeader += "#{clsGen.interface}\n"
          classSource += "\n\n\n#{clsGen.implementation}"

          files.add(cls.parsed.fileLocation)
        end
      end

      @header += files.map{ |path| generateInclude(path) }.join("\n")
      @header += "\n#include \"#{TYPE_NAMESPACE}/RuntimeHelpers.h\"\n\n"

      @header += "namespace #{library.name}
{
#{library.exportMacro} const bondage::Library &bindings();
}\n\n"

      @source += "bondage::Library #{libraryName};
namespace #{library.name}
{
const bondage::Library &bindings()
{
  return #{libraryName};
}
}"

      @header += classHeader
      @source += classSource

    end

  private
    def generateInclude(libraryfile)
      path = Pathname.new(libraryfile).relative_path_from(@libraryPath).cleanpath
      return "#include \"#{path}\""
    end

    def setLibrary(lib)
      @library = lib
      @libraryPath = Pathname.new(lib.root)
    end
  end

  # Generate exposure output in c++ for classes.
  class Generator
    # Create a generator for a [library], with a given [exposer]
    def initialize(library, exposer)
      @library = library
      @exposer = exposer
    end

    # Generate C++ output into [dir]
    def generate(dir)
      # toGenerate is the metadata which should be exposed in this library.
      toGenerate = @exposer.exposedMetaData

      # All exposed classes are dumped into one header file.
      File.open(dir + "/#{@library.name}.h", 'w') do |file|
        writePreamble(file)

        toGenerate.fullTypes.each do |clsPath, cls|
          if(cls.type == :class)
            if(!cls.hasParentClass())
              file.write("COBRA_EXPOSED_CLASS(#{clsPath})\n")
            else
              file.write("COBRA_EXPOSED_DERIVED_CLASS(#{clsPath}, #{cls.parentClass})\n")
            end
          end
        end
      end

      # All exposed classes are dumped into one C++ file.
      File.open(dir + "/#{@library.name}.cpp", 'w') do |file|
        writePreamble(file)

        toGenerate.fullTypes.map{ |clsPath, cls| "#{generateClassData(cls)}\n" }.each { |data| file.write(data) }
      end
    end

  private
    # Generate binding data for a class
    def generateClassData(cls)
      # parsed is the ExposeAst data for a class, which is not present in classes restored from JSON
      parsed = cls.parsed
      raise "Can't generate for restored class '#{cls.name}'" unless parsed

      # find a name that is a valid literal in c++ used for static definitions
      fullyQualified = parsed.fullyQualifiedName()
      literalName = fullyQualified.sub("::", "").gsub("::", "_")

      methodsLiteral = literalName + "_methods";

      parent = cls.parentClass

      classInfo = ""
      if(!parent)
        classInfo +=
  "COBRA_IMPLEMENT_EXPOSED_CLASS(
    #{fullyQualified},
    #{methodsLiteral})"
      else
        classInfo +=
  "COBRA_IMPLEMENT_DERIVED_EXPOSED_CLASS(
    #{fullyQualified},
    #{methodsLiteral},
    #{parent})"
      end

      output =
  "// Exposing class #{fullyQualified}

  const #{TYPE_NAMESPACE}::function #{methodsLiteral}[] = #{generateMethodData(parsed)};

  #{classInfo}

  "
      return output
    end

    # Generate function exposure data for [cls]
    def generateMethodData(cls)
      functions = @exposer.findExposedFunctions(cls)

      # for each function, work out how best to call it.
      fns = functions.sort.map do |name, fns|
        if(fns.length == 1)
          fn = fns[0]
          generateSingularMethod(fns[0])
        else
          functions = fns.map{ |fn| "&#{fn.fullyQualifiedName()}" }.join(",\n    ")
          "#{TYPE_NAMESPACE}::function_builder::build_overloaded<\n    #{functions}>(\"#{name}\")"
        end
      end

      return "{\n  #{fns.join(",\n  ")}\n}"
    end

    # generate an expose signature for a singlular method.
    def generateSingularMethod(fn)
      "#{TYPE_NAMESPACE}::function_builder::build<&#{fn.fullyQualifiedName()}>(\"#{fn.name}\")"
    end

    # write the pre amble for a C++ file to [file]
    def writePreamble(file)
      #Object.send(:writePreamble, file, "// ")
    end
  end
end
