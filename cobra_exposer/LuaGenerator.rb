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
  			file.write(generateClassData(cls.parsedClass))
			end
    end
  end

  def generateClassData(cls)
    functions = {}

    exposableFunctions = cls.functions.select{ |fn| @exposer.canExposeMethod(fn) }

    exposableFunctions.each do |fn|
      if(functions[fn.name] == nil)
        functions[fn.name] = []
      end

      functions[fn.name] << fn
    end

    fns = functions.sort.map do |name, fns|
    	"#{name} = internal.getNative(\"#{@library.name}\", \"#{name}\")"
    end

    classData = fns.join(",\n  ")
  	return "-- Class #{@library.name}.#{cls.name}\nlocal #{cls.name}_cls = class \"#{cls.name}\" {\n  #{classData}\n}\n\nreturn #{cls.name}_cls"
  end
end