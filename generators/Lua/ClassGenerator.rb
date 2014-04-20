require_relative "../../exposer/ExposeAst.rb"
require_relative "Function/Generator.rb"
require_relative "EnumGenerator.rb"

module Lua

  # Generate lua exposing code for C++ classes
  class ClassGenerator
    def initialize(classPlugins, classifiers, externalLine, lineStart, getter, resolver)
      @lineStart = lineStart
      @plugins = classPlugins
      @fnGen = Function::Generator.new(classifiers, externalLine, @lineStart, getter)
      @enumGen = Lua::EnumGenerator.new(@lineStart)
      @resolver = resolver
    end

    attr_reader :classDefinition

    def reset
      @classDefinition = ""
    end

    # Generate the lua class data for [cls]
    def generate(library, exposer, cls, localVarOut)
      parsed = cls.parsed

      @plugins.each { |n, plugin| plugin.beginClass(library, parsed) }

      requiredClasses = Set.new
      formattedFunctions, extraData = generateFunctions(library, exposer, parsed, requiredClasses)


      # if [cls] has a parent class, find its data and require path.
      parentInsert = generateClassParentData(exposer, cls)

      enumInsert = generateEnums(parsed, exposer)

      # find a brief comment for [cls]
      brief = parsed.comment.strippedCommand("brief")

      extraDatas = ""
      if (extraData.length != 0)
        extraDatas = extraData.join("\n\n") + "\n\n"
      end


      pluginInsert = ""
      pluginInsertData = @plugins.map { |n, plugin|
        plugin.endClass(@lineStart, requiredClasses)
      }.select{ |r|
        r != nil && !r.empty?
      }

      if (pluginInsertData.length != 0)
        pluginInsert = "\n" + pluginInsertData.join(",\n\n") + ",\n"
      end

      inc = generateIncludes(exposer, requiredClasses)

      # generate class output.
      @classDefinition = "#{inc}#{extraDatas}-- \\brief #{brief}
--
local #{localVarOut} = class \"#{cls.name}\" {
#{parentInsert}#{pluginInsert}#{enumInsert}
#{formattedFunctions.join(",\n\n")}
}"
    end

  private
    def generateIncludes(exposer, clss)
      if (clss.length == 0)
        return ""
      end

      return clss.map{ |clsName| 
        cls = exposer.allMetaData.findClass(clsName)
        "require \"#{@resolver.pathFor(cls)}\""
        }.join("\n") + "\n\n"
    end

    def generateEnums(parsed, exposer)
      @enumGen.generate(parsed, exposer)

      if (@enumGen.enums.length == 0)
        return ""
      end

      out = @enumGen.enums.map { |enum|
         "#{enum}"
      }.join("\n,\n")

      return "\n#{out},\n"
    end

    def isPluginInterested(name, fns)
      interested = []
      @plugins.each do |pluginName, plugin|
        if (plugin.interestedInFunctions?(name, fns))
          interested << plugin
        end
      end

      return interested.length > 0 ? interested : nil
    end

    def generateFunction(library, parsed, name, fns, formattedFunctions, extraData, requiredClasses)
      @fnGen.generate(library, parsed, fns, requiredClasses)

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
        
        pluginInterested.each{ |p| p.addFunctions(name, fns, bind) }
      end

      formattedFunctions << "#{@fnGen.docs}\n#{@lineStart}#{name} = #{bind}"
    end

    def generateFunctions(library, exposer, parsed, requiredClasses)
      functions = exposer.findExposedFunctions(parsed) 

      extraData = []
      formattedFunctions = []

      # for each function, work out how best to call it.
      functions.sort.each do |name, fns|
        generateFunction(library, parsed, name, fns, formattedFunctions, extraData, requiredClasses)
      end

      return formattedFunctions, extraData
    end

    def generateClassParentData(exposer, cls)
      # if [cls] has a parent class, find its data and require path.
      parentInsert = ""
      if(cls.parentClass)
        parent = exposer.allMetaData.findClass(cls.parentClass)
        raise "Missing parent dependency '#{ls.parentClass}'" unless parent

        parentName = "#{parent.name}_cls"

        parentRequirePath = @resolver.pathFor(parent)

        parentInsert = "  super = require \"#{parentRequirePath}\",\n"
      end

      return parentInsert
    end
  end

end