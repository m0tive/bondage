require_relative "../../exposer/ExposeAst.rb"
require_relative "Function/Generator.rb"
require_relative "EnumGenerator.rb"

module Lua

  # Generate lua exposing code for C++ classes
  class ClassGenerator
    def initialize(classPlugins, classifiers, lineStart, getter)
      @lineStart = lineStart
      @plugins = classPlugins
      @fnGen = Function::Generator.new(classifiers, @lineStart, getter)
      @enumGen = Lua::EnumGenerator.new(@lineStart)
    end

    attr_reader :classDefinition

    def reset
      @classDefinition = ""
    end

    # Generate the lua class data for [cls]
    def generate(library, exposer, luaPathResolver, cls, localVarOut)
      parsed = cls.parsed
      functions = exposer.findExposedFunctions(parsed)

      extraData = []

      formattedFunctions = []

      pluginData = { }

      # for each function, work out how best to call it.
      functions.sort.each do |name, fns|
        @fnGen.generate(library, parsed, fns)

        bind = @fnGen.bind
        name = @fnGen.name

        globalData = false
        @plugins.each do |plugin|
          if (plugin.interested?(library, parsed, fns))
            plugin.addData(library, parsed, fns, name)
            globalData = true
          end
        end

        if (@fnGen.wrapper.length != 0)
          extraData << @fnGen.wrapper
        end


        if (globalData)
          varName = ""
          if (@fnGen.bindIsForwarder)
            varName = bind
          else
            varName = "#{parsed.name}_#{name}_fwd"
            extraData << "local #{varName} = #{bind}"
          end
          formattedFunctions << "#{@fnGen.docs}\n#{@lineStart}#{name} = #{varName}"
        else
          formattedFunctions << "#{@fnGen.docs}\n#{@lineStart}#{name} = #{bind}"
        end
      end

      # if [cls] has a parent class, find its data and require path.
      parentInsert = generateClassParentData(exposer, luaPathResolver, cls)

      enumInsert = ""
      @enumGen.generate(parsed)
      @enumGen.enums.each do |enum|
        enumInsert << "\n#{enum},\n"
      end

      # find a brief comment for [cls]
      brief = parsed.comment.strippedCommand("brief")

      extraDatas = ""
      if (extraData.length != 0)
        extraDatas = extraData.join("\n\n") + "\n\n"
      end

      # generate class output.
      @classDefinition = "#{extraDatas}-- \\brief #{brief}
--
local #{localVarOut} = class \"#{cls.name}\" {
#{parentInsert}#{enumInsert}
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