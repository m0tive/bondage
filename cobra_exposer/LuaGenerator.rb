require_relative "ExposeAST.rb"

class LuaGenerator
  def initialize(library, exposer)
    @library = library
    @exposer = exposer
  end

  def generate(dir)
    classPaths = toGenerate = @exposer.exposedMetaData.fullClasses.each do |path, cls|
      puts "Exposing #{cls.name} to lua"
  		File.open(dir + "/#{cls.name}.lua", 'w') do |file|
  			file.write(generateClassData(cls))
			end
    end
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
    	"#{name} = internal.getNative(\"#{@library.name}\", \"#{name}\")"
    end

    name = cls.name

    parentInsert = ""
    parentPreamble = ""
    if(cls.parentClass)
      parent = @exposer.allMetaData.findClass(cls.parentClass)
      raise "Missing parent dependency '#{ls.parentClass}'" unless parent

      parentName = "#{parent.name}_def"

      parentInsert = "  super = #{parentName},\n\n  "
      parentPreamble = "local #{parentName} = require \"#{parent.name}\"\n\n"
    end

    classData = fns.join(",\n  ")
  	output = parentPreamble
    output += "-- Class #{@library.name}.#{name}\n"
    output += "local #{name}_cls = class \"#{name}\" {\n"
    output += parentInsert
    output += "#{classData}\n}\n\nreturn #{name}_cls"
  end
end