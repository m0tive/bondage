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

  def generateFunction(name, fns)
    output = ""

    brief = ""
    returnComment = ""
    cmds = { }

    puts "funtion #{fns[0].name}"

    fns.each do |fn|
      if(fn.comment.hasCommand("brief"))
        brief = fn.comment.command("brief").strip

        if (!fn.returnBrief.empty? && returnComment.empty?)
          returnComment = fn.returnBrief.strip
        end

        fn.arguments.each do |arg|
          puts "Arg #{arg.name} #{arg.brief.strip} #{arg.input?} #{arg.output?}"
        end
      end
    end

    puts "reutrn comment = #{returnComment}"

    output += "#{name} = internal.getNative(\"#{@library.name}\", \"#{name}\")"
    return output
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
    	generateFunction(name, fns)
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

    classData = fns.join(",\n\n  ")

  	output = parentPreamble
    output += "-- \\brief #{brief}\n"
    output += "--\nlocal #{name}_cls = class \"#{name}\" {\n"
    output += parentInsert
    output += "\n  #{classData}\n}\n\nreturn #{name}_cls"
  end
end