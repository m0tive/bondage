require_relative "ExposeAST.rb"

class LuaGenerator
  def initialize(library, exposer)
    @library = library
    @exposer = exposer
  end

  def generate(dir)
    classPaths = toGenerate = @exposer.exposedMetaData.fullClasses.each do |path, cls|
  		File.open(dir + "/#{cls.name}.lua", 'w') do |file|
  			file.write(generateClassData(cls))
			end
    end
  end

  def generateFunction(name, cls, fns)

    brief = ""
    returnComment = ""
    args = { }
    signatures = []

    puts "funtion #{fns[0].name}"

    fns.each do |fn|
      if(fn.comment.hasCommand("brief"))
        brief = fn.comment.command("brief").strip
      end

      argIndexed = []

      if (!fn.returnBrief.empty? && returnComment.empty?)
        returnComment = fn.returnBrief.strip
      end

      fn.arguments.each do |arg|
        args[arg.name] = arg
        argIndexed << arg
      end

      callConv = fn.static ? "." : ":"
      argString = argIndexed.map{ |arg| "#{formatType(arg.type)} #{arg.name}" }.join(", ")

      signatures << "#{formatType(fn.returnType)} #{cls.name}#{callConv}#{name}(#{argString})"
    end

    puts "reutrn comment = #{returnComment}"

    comment = signatures.map{ |sig| "  -- #{sig}" }.join("\n")
    comment += "\n  -- \\brief #{brief}"
    args.to_a.sort.each do |argName, arg|
      if(!argName.empty? && !arg.brief.empty?)
        comment += "\n  -- \\param #{argName} #{arg.brief.strip}"
      end
    end


    output = comment + "\n  #{name} = internal.getNative(\"#{@library.name}\", \"#{name}\")"
    return output
  end

  def formatType(type)
    return type ? "#{type.prettyName}" : "nil"
  end

  def generateClassData(cls)
    parsedClass = cls.parsedClass
    functions = {}

    exposableFunctions = parsedClass.functions.select{ |fn| @exposer.canExposeMethod(fn) }

    exposableFunctions.each do |fn|
      if(functions[fn.name] == nil)
        functions[fn.name] = []
      end

      functions[fn.name] << fn
    end

    fns = functions.sort.map do |name, fns|
    	generateFunction(name, cls, fns)
    end

    name = cls.name

    brief = ""
    if(parsedClass.comment.hasCommand("brief"))
      brief = parsedClass.comment.command("brief").strip
    end

    parentInsert = ""
    parentPreamble = ""
    if(cls.parentClass)
      parent = @exposer.allMetaData.findClass(cls.parentClass)
      raise "Missing parent dependency '#{ls.parentClass}'" unless parent

      parentName = "#{parent.name}_cls"

      parentInsert = "  super = #{parentName},\n"
      parentPreamble = "local #{parentName} = require \"#{parent.name}\""
    end

    classData = fns.join(",\n\n")

  	output = parentPreamble
    output += "-- \\brief #{brief}\n"
    output += "--\nlocal #{name}_cls = class \"#{name}\" {\n"
    output += parentInsert
    output += "\n#{classData}\n}\n\nreturn #{name}_cls"
  end
end