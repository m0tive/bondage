require_relative "ExposeAst.rb"
require_relative "GeneratorHelper.rb"

# Generate lua exposing code for C++ classes
class LuaGenerator
  # create a lua generator for a [library], and a given [exposer].
  def initialize(library, exposer)
    @library = library
    @exposer = exposer
  end

  # Generate lua classes into [dir]
  def generate(dir)

    # for each fully exposed class, we write a file containing the classes methods and data.
    @exposer.exposedMetaData.fullClasses.each do |path, cls|
		File.open(dir + "/#{cls.name}.lua", 'w') do |file|
        writePreamble(file, "-- ")
			file.write(generateClassData(cls))
			end
    end
  end

  # generate exposing data for a set of named functions [fns], with [name], for class [cls].
  def generateFunction(name, cls, fns)

    brief = ""
    returnComment = ""
    args = { }
    signatures = []

    # for each function, find argument docs, return docs (only one of these
    # is used), and briefs (only one is used.)
    fns.each do |fn|
      if(fn.comment.hasCommand("brief"))
        brief = fn.comment.command("brief").strip
      end

      argIndexed = []

      # extract return comment.
      if (!fn.returnBrief.empty? && returnComment.empty?)
        returnComment = fn.returnBrief.strip
      end

      # exract arg comments
      fn.arguments.each do |arg|
        args[arg.name] = arg
        argIndexed << arg
      end

      # extract signature
      callConv = fn.static ? "." : ":"
      argString = argIndexed.map{ |arg| "#{formatType(arg.type)} #{arg.name}" }.join(", ")

      signatures << "#{formatType(fn.returnType)} #{cls.name}#{callConv}#{name}(#{argString})"
    end

    # format the signatures with the param comments to form the preable for a funtion.
    comment = signatures.map{ |sig| "  -- #{sig}" }.join("\n")
    comment += "\n  -- \\brief #{brief}"
    args.to_a.sort.each do |argName, arg|
      if(!argName.empty? && !arg.brief.empty?)
        comment += "\n  -- \\param #{argName} #{arg.brief.strip}"
      end
    end

    if(!returnComment.empty?)
      comment += "\n  -- \\return #{returnComment}"
    end

    # exposure for a function is the comment, then the native extraction.
    return comment + "\n  #{name} = internal.getNative(\"#{@library.name}\", \"#{name}\")"
  end

  # Format [type], a Type instance, in a way lua users can understand
  def formatType(type)
    # void maps to nil
    if(!type || type.isVoid())
      return "nil"
    end

    # char pointers map to string
    if(type.isStringLiteral())
      return "string"
    end

    # pointers and references are stripped (after strings!)
    if(type.isPointer() || type.isLValueReference() || type.isLValueReference())
      return formatType(type.pointeeType())
    end

    # bool is boolean
    if(type.isBoolean())
      return "boolean"
    end

    # all int/float/double types are numbers
    if(type.isInteger() || type.isFloatingPoint())
      return "number"
    end

    return "#{type.name}"
  end

  # Generate the lua class data for [cls]
  def generateClassData(cls)
    parsedClass = cls.parsedClass
    functions = @exposer.findExposedFunctions(cls)

    # generate functions for each group, so fns is a set of overloaded method exposures.
    fns = functions.sort.map do |name, fns|
      generateFunction(name, cls, fns)
    end

    name = cls.name

    # find a brief comment for [cls]
    brief = ""
    if(parsedClass.comment.hasCommand("brief"))
      brief = parsedClass.comment.command("brief").strip
    end

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

    classData = fns.join(",\n\n")

    # generate class output.
	output = parentPreamble

    output += "
-- \\brief #{brief}
--
local #{name}_cls = class \"#{name}\" {
#{parentInsert}
#{classData}
}

return #{name}_cls"
  end
end