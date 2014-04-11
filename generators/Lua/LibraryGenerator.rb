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
      @clsGen = ClassGenerator.new(@lineStart, getter)
    end

    # Generate lua classes into [dir]
    def generate(library, exposer)
      @classes = { }
      @libraryName = library.name


      # for each fully exposed class, we write a file containing the classes methods and data.
      exposer.exposedMetaData.fullTypes.each do |path, cls|
        if(cls.type == :class)
          @clsGen.generate(library, exposer, @pathResolver, cls, localName(cls))

          @classes[cls] = @clsGen.classDefinition
        end
      end

      files = @classes.map{ |cls, data| "  #{cls.name} = require(\"#{@pathResolver.pathFor(cls)}\")" }
      fileData = files.join("\n")

      @libraryDef = "local #{@libraryName} = {\n#{fileData}\n}\n\nreturn #{@libraryName}"
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

  end

end