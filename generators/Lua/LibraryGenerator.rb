require_relative "../../exposer/ExposeAst.rb"
require_relative "../GeneratorHelper.rb"
require_relative "RequireHelper.rb"
require_relative "ClassGenerator.rb"

module Lua

  # Generate lua exposing code for C++ classes
  class LibraryGenerator
    # create a lua generator for a [library], and a given [exposer].
    def initialize(classPlugins, classifiers, getter, resolver)
      @lineStart = "  "
      @pathResolver = resolver
      @classes = { }
      @getter = getter
      @classifiers = classifiers
      @clsGen = ClassGenerator.new(classPlugins, classifiers, "", @lineStart, getter, resolver)
    end

    attr_reader :classes, :library

    # Generate lua classes into [dir]
    def generate(visitor, exposer)
      library = visitor.library
      @classes = { }
      @libraryName = library.name


      # for each fully exposed class, we write a file containing the classes methods and data.
      exposer.exposedMetaData.fullTypes.each do |path, cls|
        if(cls.type == :class)
          @clsGen.generate(library, exposer, cls, localName(cls))

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
        file.write(@library)
      end
    end

    def localName(cls)
      return "#{cls.name}_cls"
    end

    def generateLibrary(exposer, library, classes, rootNs)
      formattedFunctions = []

      ls = "#{@lineStart}"

      data = @classes.map{ |cls, data| "#{ls}#{cls.name} = require(\"#{@pathResolver.pathFor(cls)}\")" }

      requiredClasses = Set.new

      appendEnums(library, exposer, rootNs, data)

      extraData = []
      appendFunctions(library, exposer, rootNs, data, extraData, requiredClasses)

      extraDatas = ""
      if (extraData.length != 0)
        extraDatas = extraData.join("\n\n") + "\n\n"
      end

      fileData = data.join(",\n\n")

      inc = Helper::generateRequires(@pathResolver, exposer, requiredClasses)

      @library = "#{inc}#{extraDatas}local #{@libraryName} = {\n#{fileData}\n}\n\nreturn #{@libraryName}"
    end

    def appendEnums(library, exposer, rootNs, data)
      enumGen = EnumGenerator.new(@lineStart)

      enumGen.generate(rootNs, exposer)
      enumGen.enums.each do |enum|
        data << "#{enum}"
      end
    end

    def appendFunctions(library, exposer, rootNs, data, extraData, requiredClasses)
      functions = exposer.findExposedFunctions(rootNs)

      # for each function, work out how best to call it.
      fnGen = Function::Generator.new(@classifiers, "", @lineStart, @getter)
      functions.sort.each do |name, fns|
        fnGen.generate(library, rootNs, fns, requiredClasses)

        if (fnGen.wrapper.length > 0)
          extraData << fnGen.wrapper
        end

        data << "#{fnGen.docs}\n#{@lineStart}#{fnGen.name} = #{fnGen.bind}"
      end
    end
  end

end