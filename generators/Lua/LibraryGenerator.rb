require_relative "../../exposer/ExposeAst.rb"
require_relative "../GeneratorHelper.rb"
require_relative "ClassGenerator.rb"

module Lua

  # Generate lua exposing code for C++ classes
  class LibraryGenerator
    # create a lua generator for a [library], and a given [exposer].
    def initialize(classPlugins, classifiers, getter, resolver)
      @lineStart = "  "
      @pathResolver = resolver
      @getter = getter
      @classifiers = classifiers
      @clsGen = ClassGenerator.new(classPlugins, classifiers, @lineStart, getter)
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
      formattedFunctions = []

      ls = "#{@lineStart}"

      data = @classes.map{ |cls, data| "#{ls}#{cls.name} = require(\"#{@pathResolver.pathFor(cls)}\")" }

      appendEnums(library, rootNs, data)

      appendFunctions(library, exposer, rootNs, data)

      extraData = []
      extraDatas = ""
      if (extraData.length != 0)
        extraDatas = extraData.join("\n\n") + "\n\n"
      end

      fileData = data.join(",\n\n")

      @libraryDef = "#{extraDatas}local #{@libraryName} = {\n#{fileData}\n}\n\nreturn #{@libraryName}"
    end

    def appendEnums(library, rootNs, data)
      enumGen = EnumGenerator.new(@lineStart)

      enumGen.generate(rootNs)
      enumGen.enums.each do |enum|
        data << "#{enum}"
      end
    end

    def appendFunctions(library, exposer, rootNs, data)
      functions = exposer.findExposedFunctions(rootNs)

      # for each function, work out how best to call it.
      fnGen = Function::Generator.new(@classifiers, @lineStart, @getter)
      functions.sort.each do |name, fns|
        fnGen.generate(library, rootNs, fns)

        data << "#{fnGen.docs}\n#{@lineStart}#{fnGen.name} = #{fnGen.bind}"
      end
    end

  end

end