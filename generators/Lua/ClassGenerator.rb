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

      @plugins.each { |n, plugin| plugin.beginClass(library, parsed) }

      formattedFunctions, extraData = generateFunctions(library, exposer, parsed)


      # if [cls] has a parent class, find its data and require path.
      parentInsert = generateClassParentData(exposer, luaPathResolver, cls)

      enumInsert = generateEnums(parsed)

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
    def generateEnums(parsed)
      @enumGen.generate(parsed)

      if (@enumGen.enums.length == 0)
        return ""
      end

      out = @enumGen.enums.map { |enum|
         "#{enum}"
      }.join("\n,\n")

      return "\n#{out},\n"
    end

    def isPluginInterested(name, fns)
      interested = false
      @plugins.each do |pluginName, plugin|
        if (plugin.interestedInFunctions?(name, fns))
          interested = true
        end
      end

      return interested
    end

    def generateFunction(library, parsed, name, fns, formattedFunctions, extraData)
      @fnGen.generate(library, parsed, fns)

      bind = @fnGen.bind
      name = @fnGen.name

      # Visit the plugins for our class, they may choose
      # to do something with this function later.
      pluginInterested = isPluginInterested(name, fns)

      if (@fnGen.wrapper.length != 0)
        extraData << @fnGen.wrapper
      end

      if (pluginInterested)
        varName = ""
        if (@fnGen.bindIsForwarder)
          varName = bind
        else
          # someone wants a reference to this function other than the def - store it in a local for passing on
          varName = "#{parsed.name}_#{name}_fwd"
          extraData << "local #{varName} = #{bind}"
        end

        bind = varName
      end

      formattedFunctions << "#{@fnGen.docs}\n#{@lineStart}#{name} = #{bind}"
    end

    def generateFunctions(library, exposer, parsed)
      functions = exposer.findExposedFunctions(parsed) 

      extraData = []
      formattedFunctions = []

      # for each function, work out how best to call it.
      functions.sort.each do |name, fns|
        generateFunction(library, parsed, name, fns, formattedFunctions, extraData)
      end

      return formattedFunctions, extraData
    end

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