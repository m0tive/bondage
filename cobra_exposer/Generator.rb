require_relative "ExposeAST.rb"
require_relative "GeneratorHelper.rb"

class Generator
  def initialize(library, exposer)
    @library = library
    @exposer = exposer
  end

  def generate(dir)
    toGenerate = @exposer.exposedMetaData

    File.open(dir + "/#{@library.name}.h", 'w') do |file|
      writePreamble(file)

      toGenerate.fullClasses.each do |clsPath, cls| 
        if(!cls.hasParentClass())
          file.write("COBRA_EXPOSED_CLASS(#{clsPath})\n")
        end
      end
    end

    File.open(dir + "/#{@library.name}.cpp", 'w') do |file|
      writePreamble(file)

      toGenerate.fullClasses.map{ |clsPath, cls| "#{generateClassData(cls)}\n" }.each { |data| file.write(data) }
    end
  end

private
  def generateClassData(cls)
    parsedClass = cls.parsedClass
    raise "Can't generate for restored class '#{cls.name}'" unless parsedClass
    fullyQualified = parsedClass.fullyQualifiedName()
    literalName = fullyQualified.sub("::", "").gsub("::", "_")

    methodsLiteral = literalName + "_methods";

    parent = cls.parentClass

    classInfo = ""
    if(!parent)
      classInfo += 
"COBRA_IMPLEMENT_EXPOSED_CLASS(
  #{fullyQualified}, 
  #{methodsLiteral})"
    else
      classInfo += 
"COBRA_IMPLEMENT_DERIVED_EXPOSED_CLASS(
  #{fullyQualified}, 
  #{methodsLiteral}, 
  #{parent})"
    end

    output = 
"// Exposing class #{fullyQualified}

const cobra::function #{methodsLiteral}[] = #{generateMethodData(parsedClass)};

#{classInfo}

";


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

  def writePreamble(file)
    Object.send(:writePreamble, file, "// ")
  end
end
