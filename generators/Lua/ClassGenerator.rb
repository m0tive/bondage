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
    def generate(library, exposer, luaPathResolver, cls, localVarOut)
      parsed = cls.parsed
      functions = exposer.findExposedFunctions(parsed)

      formattedFunctions = []

      # for each function, work out how best to call it.
      functions.sort.each do |name, fns|
        @fnGen.generate(library, cls, fns)

        formattedFunctions << "#{@fnGen.docs}\n#{@lineStart}#{@fnGen.classDefinition}"
      end

      # if [cls] has a parent class, find its data and require path.
      parentInsert = generateClassParentData(exposer, luaPathResolver, cls)

      # find a brief comment for [cls]
      brief = parsed.comment.strippedCommand("brief")

      # generate class output.
      @classDefinition = "-- \\brief #{brief}
--
local #{localVarOut} = class \"#{cls.name}\" {
#{parentInsert}
#{formattedFunctions.join(",\n\n")}
}"
    end

  private
    def generateClassParentData(exposer, luaPathResolver, cls)
      # if [cls] has a parent class, find its data and require path.
      parentInsert = ""
      if(cls.parentClass)
        parent = exposer.allMetaData.findClass(cls.parentClass)
        raise "Missing parent dependency '#{ls.parentClass}'" unless parent

        parentName = "#{parent.name}_cls"

        parentRequirePath = luaPathResolver.pathFor(parent)

        parentInsert = "  super = require \"#{parentRequirePath}\",\n"
      end

      return parentInsert
    end
  end

end