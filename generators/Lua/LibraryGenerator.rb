require_relative "../../exposer/ExposeAst.rb"
require_relative "../GeneratorHelper.rb"
require_relative "FunctionGenerator.rb"

module Lua

  # Generate lua exposing code for C++ classes
  class LibraryGenerator
    # create a lua generator for a [library], and a given [exposer].
    def initialize(getter)
      @lineStart = "  "
      @fnGen = FunctionGenerator.new(@lineStart, getter)
    end

    # Generate lua classes into [dir]
    def generate(library, exposer)
      @library = library
      @exposer = exposer
      @classes = { }


      # for each fully exposed class, we write a file containing the classes methods and data.
      @exposer.exposedMetaData.fullTypes.each do |path, cls|
        if(cls.type == :class)
          @classes[cls] = generateClassData(cls)
        end
      end
    end

    def write(dir)
      @classes.each do |cls, data|
        File.open(dir + "/#{cls.name}.lua", 'w') do |file|
          file.write(filePreamble("--") + "\n\n")
          file.write(data)
        end
      end
    end

    # Generate the lua class data for [cls]
    def generateClassData(cls)
      parsed = cls.parsed
      functions = @exposer.findExposedFunctions(parsed)

      formattedFunctions = []

      # for each function, work out how best to call it.
      functions.sort.each do |name, fns|
        @fnGen.generate(@library, cls, fns)

        formattedFunctions << "#{@fnGen.docs}\n#{@lineStart}#{@fnGen.classDefinition}"
      end

      # if [cls] has a parent class, find its data and require path.
      parentInsert, parentPreamble = generateClassParentData(cls)

      # find a brief comment for [cls]
      brief = parsed.comment.strippedCommand("brief")

      # generate class output.
      output = "#{parentPreamble}
-- \\brief #{brief}
--
local #{cls.name}_cls = class \"#{cls.name}\" {
#{parentInsert}
#{formattedFunctions.join(",\n\n")}
}

return #{cls.name}_cls"
    end

  private
    def generateClassParentData(cls)
      # if [cls] has a parent class, find its data and require path.
      parentInsert = ""
      parentPreamble = ""
      if(cls.parentClass)
        parent = @exposer.allMetaData.findClass(cls.parentClass)
        raise "Missing parent dependency '#{ls.parentClass}'" unless parent

        parentName = "#{parent.name}_cls"

        parentInsert = "  super = #{parentName},\n"
        parentPreamble = "local #{parentName} = require \"#{parent.name}\"\n"
      end

      return parentInsert, parentPreamble
    end
  end

end