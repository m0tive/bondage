require_relative "../../exposer/ExposeAst.rb"
require_relative "../GeneratorHelper.rb"
require_relative "../../exposer/FunctionVisitor.rb"

require_relative "FunctionGenerator.rb"
require_relative "ClassGenerator.rb"

require 'pathname'

module CPP

  class LibraryGenerator
    
    class DerivedClass
      def initialize(literalName, path, rootPath, distance)
        @literalName = literalName
        @path = path
        @rootPath = rootPath
        @distance = distance
      end

      attr_reader :literalName, :path, :rootPath, :distance
    end

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

    def generate(visitor, exposer)
      library = visitor.library
      rootNs = visitor.getExposedNamespace()
      setLibrary(library)

      @header = filePreamble("//") + "\n\n" 
      @source = filePreamble("//") + "\n"
      @source += generateInclude(headerPath(library))
      sourcefiles = [ TYPE_NAMESPACE + "/RuntimeHelpersImpl.h", "utility", "tuple" ]

      library.dependencies.each{ |l| sourcefiles << headerPath(l) }

      @source += "\n" + sourcefiles.map{ |f| "#include \"#{f}\"" }.join("\n") + "\n\n\n"

      clsGen = ClassGenerator.new

      files = Set.new
      derivedClasses = Set.new

      libraryName = "g_bondage_library_#{library.name}";

      classHeader = ""
      classSource = ""

      exposer.exposedMetaData.types.each do |path, cls|
        if (cls.type == :class && cls.fullyExposed)
          clsGen.reset()
          clsGen.generate(exposer, cls, libraryName)
          classHeader += "#{clsGen.interface}\n"
          classSource += "\n\n\n#{clsGen.implementation}"

          files << cls.parsed.fileLocation

          if (cls.parentClass)
            rootPath, distance = clsGen.findRootClass(cls)

            derivedClasses << DerivedClass.new(clsGen.wrapperName, path, rootPath, distance)
          end
        end
      end

      generateLibrary(libraryName, library, exposer, rootNs, files)

      @header += classHeader
      @source += classSource

      @source += "\n\n" + generateDerivedCasts(clsGen, derivedClasses)
    end

  private
    def generateLibrary(libraryName, library, exposer, rootNs, files)
      raise "Invalid root namespace for #{library.name}." unless rootNs

      @header += files.map{ |path| generateInclude(path) }.join("\n")
      @header += "\n#include \"#{TYPE_NAMESPACE}/RuntimeHelpers.h\"\n\n"

      @header += "namespace #{library.name}
{
#{library.exportMacro} const bondage::Library &bindings();
}\n\n"

      fnGen = CPP::FunctionGenerator.new("", "  ")
      methods, extraMethods = fnGen.gatherFunctions(rootNs, exposer)

      methodsLiteral, methodsArray, extraMethodSource = fnGen.generateFunctionArray(methods, extraMethods, libraryName)

      @source += "#{extraMethodSource}#{methodsArray}
bondage::Library #{libraryName}(
  \"#{library.name}\",
  #{methodsLiteral},
  #{methods.length});
namespace #{library.name}
{
const bondage::Library &bindings()
{
  return #{libraryName};
}
}"

    end

    def generateInclude(libraryfile)
      path = Pathname.new(libraryfile).relative_path_from(@libraryPath).cleanpath
      return "#include \"#{path}\""
    end

    def generateDerivedCasts(clsGen, clss)
      byRoots = { }

      clss.each do |classData|
        arr = byRoots[classData.rootPath]
        if (!arr)
          arr = []
          byRoots[classData.rootPath] = arr
        end

        arr << classData
      end

      output = ""
      byRoots.each do |root, classes|
        output += generateDerivedCast(root, classes) + "\n\n"
      end

      return output
    end

    def generateDerivedCast(root, classes)
      rootNiceName = root.sub("::", "").gsub("::", "_")
      functionName = "#{@library.name}_#{rootNiceName}_caster"
      output = "#include \"CastHelper.#{rootNiceName}.h\"\n\n"
      output += "const bondage::WrappedClass *#{functionName}(const void *vPtr)\n{\n"

      output += "  auto ptr = static_cast<const #{root}*>(vPtr);\n\n"

      classes.sort_by{ |a| a.distance }.reverse.each do |derived|
        output += "  if (Crate::CastHelper< #{root}, #{derived.path} >::canCast(ptr))\n  {\n    return &#{derived.literalName};\n  }\n"
      end

      output += "  return nullptr;"

      output += "\n}\n\n"

      output += "bondage::CastHelperLibrary g_#{functionName}(bondage::WrappedClassFinder< #{root} >::castHelper(), #{functionName});"
      return output
    end

    def setLibrary(lib)
      @library = lib
      @libraryPath = Pathname.new(lib.root)
    end
  end
end
