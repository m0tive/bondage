require_relative "../../exposer/ExposeAst.rb"
require_relative "FunctionGenerator.rb"

module Lua

  # Generate lua exposing code for C++ classes
  class ClassGenerator
    def initialize(lineStart, getter)
      @lineStart = lineStart
      @fnGen = FunctionGenerator.new(@lineStart, getter)
    end

    attr_reader :classDefinition

    def reset
      @classDefinition = ""
    end

    # Generate the lua class data for [cls]
    def generate(library, exposer, cls)
      parsed = cls.parsed
      functions = exposer.findExposedFunctions(parsed)

      formattedFunctions = []

      # for each function, work out how best to call it.
      functions.sort.each do |name, fns|
        @fnGen.generate(library, cls, fns)

        formattedFunctions << "#{@fnGen.docs}\n#{@lineStart}#{@fnGen.classDefinition}"
      end

      # if [cls] has a parent class, find its data and require path.
      parentInsert, parentPreamble = generateClassParentData(exposer, cls)

      # find a brief comment for [cls]
      brief = parsed.comment.strippedCommand("brief")

      # generate class output.
      @classDefinition = "#{parentPreamble}
-- \\brief #{brief}
--
local #{cls.name}_cls = class \"#{cls.name}\" {
#{parentInsert}
#{formattedFunctions.join(",\n\n")}
}

return #{cls.name}_cls"
    end

  private
    def generateClassParentData(exposer, cls)
      # if [cls] has a parent class, find its data and require path.
      parentInsert = ""
      parentPreamble = ""
      if(cls.parentClass)
        parent = exposer.allMetaData.findClass(cls.parentClass)
        raise "Missing parent dependency '#{ls.parentClass}'" unless parent

        parentName = "#{parent.name}_cls"

        parentInsert = "  super = #{parentName},\n"
        parentPreamble = "local #{parentName} = require \"#{parent.name}\"\n"
      end

      return parentInsert, parentPreamble
    end
  end

end