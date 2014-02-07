require_relative "ExposeAST.rb"

class Generator
  def initialize(library, exposer)
    @library = library
    @exposer = exposer
  end

  def generate(dir)
    toGenerate = @exposer.exposedMetaData

    File.open(dir + "/#{@library.name}.h", 'w') do |file|
      toGenerate.fullClasses.map{ |clsPath, cls| "COBRA_EXPOSED_CLASS(#{clsPath})\n" }.each { |data| file.write(data) }
    end

    File.open(dir + "/#{@library.name}.cpp", 'w') do |file|
      toGenerate.fullClasses.map{ |clsPath, cls| "#{generateClassData(cls.parsedClass)}\n" }.each { |data| file.write(data) }
    end
  end

private
  def generateClassData(cls)
    fullyQualified = cls.fullyQualifiedName()
    literalName = fullyQualified.sub("::", "").gsub("::", "_")

    methodsLiteral = literalName + "_methods";

    output = "// Exposing class #{fullyQualified}\n\n"
    output += "const cobra::function #{methodsLiteral}[] = #{generateMethodData(cls)};\n\n";
    output += "COBRA_IMPLEMENT_EXPOSED_CLASS(#{fullyQualified}, #{methodsLiteral})\n\n"

    return output
  end

  def generateMethodData(cls)
    functions = {}

    exposableFunctions = cls.functions.select{ |fn| @exposer.canExposeMethod(fn) }

    exposableFunctions.each do |fn|
      if(functions[fn.name] == nil)
        functions[fn.name] = []
      end

      functions[fn.name] << fn
    end

    fns = functions.sort.map do |name, fns|
      if(fns.length == 1)
        fn = fns[0]
        generateSingularMethod(fns[0])
      else
        functions = fns.map{ |fn| "&#{fn.fullyQualifiedName()}" }.join(",\n    ")
        "cobra::function_builder::build_overloaded<\n    #{functions}>(\"#{name}\")"
      end
    end

    return "{\n  #{fns.join(",\n  ")}\n}"
  end

  def generateSingularMethod(fn)
    "cobra::function_builder::build<&#{fn.fullyQualifiedName()}>(\"#{fn.name}\")"
  end
end
