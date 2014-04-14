require_relative "../../exposer/ExposeAst.rb"
require_relative "../GeneratorHelper.rb"
require_relative "ClassGenerator.rb"

module Lua

  # Generate lua exposing code for C++ classes
  class LibraryGenerator
    # create a lua generator for a [library], and a given [exposer].
    def initialize(getter, resolver)
      @lineStart = "  "
      @pathResolver = resolver
      @getter = getter
      @clsGen = ClassGenerator.new(@lineStart, getter)
    end

    # Generate lua classes into [dir]
    def generate(visitor, exposer)
      library = visitor.library
      @classes = { }
      @libraryName = library.name


      # for each fully exposed class, we write a file containing the classes methods and data.
      exposer.exposedMetaData.fullTypes.each do |path, cls|
        if(cls.type == :class)
          @clsGen.generate(library, exposer, @pathResolver, cls, localName(cls))

          @classes[cls] = @clsGen.classDefinition
        end
      end

      generateLibrary(exposer, library, @classes, visitor.getExposedNamespace())
    end

    def write(dir)
      @classes.each do |cls, data|
        File.open(dir + "/#{cls.name}.lua", 'w') do |file|
          file.write(filePreamble("--") + "\n\n")
          file.write(data)
          file.write("\n\nreturn #{localName(cls)}")
        end
      end

      File.open(dir + "/#{@libraryName}Library.lua", 'w') do |file|
        file.write(filePreamble("--") + "\n\n")
        file.write(@libraryDef)
      end
    end

    def localName(cls)
      return "#{cls.name}_cls"
    end

    def generateLibrary(exposer, library, classes, rootNs)
      functions = exposer.findExposedFunctions(rootNs)

      formattedFunctions = []

      ls = "#{@lineStart}"

      data = @classes.map{ |cls, data| "#{ls}#{cls.name} = require(\"#{@pathResolver.pathFor(cls)}\")" }

      enumGen = Lua::EnumGenerator.new(@lineStart)

      enumGen.generate(rootNs)
      enumGen.enums.each do |enum|
        data << "#{enum}"
      end


      # for each function, work out how best to call it.
      fnGen = FunctionGenerator.new(@lineStart, @getter)
      functions.sort.each do |name, fns|
        fnGen.generate(library, rootNs, fns)

        data << "#{fnGen.docs}\n#{@lineStart}#{fnGen.classDefinition}"
      end

      fileData = data.join(",\n\n")

      @libraryDef = "local #{@libraryName} = {\n#{fileData}\n}\n\nreturn #{@libraryName}"
    end

  end

end