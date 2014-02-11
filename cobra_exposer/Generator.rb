require_relative "ExposeAST.rb"
require_relative "GeneratorHelper.rb"

# Generate exposure output in c++ for classes.
class Generator
  # Create a generator for a [library], with a given [exposer]
  def initialize(library, exposer)
    @library = library
    @exposer = exposer
  end

  # Generate C++ output into [dir]
  def generate(dir)
    # toGenerate is the metadata which should be exposed in this library.
    toGenerate = @exposer.exposedMetaData

    # All exposed classes are dumped into one header file.
    File.open(dir + "/#{@library.name}.h", 'w') do |file|
      writePreamble(file)

      toGenerate.fullClasses.each do |clsPath, cls| 
        if(!cls.hasParentClass())
          file.write("COBRA_EXPOSED_CLASS(#{clsPath})\n")
        else
          file.write("COBRA_EXPOSED_DERIVED_CLASS(#{clsPath}, #{cls.parentClass})\n")
        end
      end
    end

    # All exposed classes are dumped into one C++ file.
    File.open(dir + "/#{@library.name}.cpp", 'w') do |file|
      writePreamble(file)

      toGenerate.fullClasses.map{ |clsPath, cls| "#{generateClassData(cls)}\n" }.each { |data| file.write(data) }
    end
  end

private
  # Generate binding data for a class
  def generateClassData(cls)
    # parsedClass is the ExposeAST data for a class, which is not present in classes restored from JSON
    parsedClass = cls.parsedClass
    raise "Can't generate for restored class '#{cls.name}'" unless parsedClass

    # find a name that is a valid literal in c++ used for static definitions
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

  # Generate function exposure data for [cls]
  def generateMethodData(cls)
    functions = {}

    # find all exposable functions as an array
    exposableFunctions = cls.functions.select{ |fn| @exposer.canExposeMethod(fn) }

    # group these functions by overload
    exposableFunctions.each do |fn|
      if(functions[fn.name] == nil)
        functions[fn.name] = []
      end

      functions[fn.name] << fn
    end

    # for each function, work out how best to call it.
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

  # generate an expose signature for a singlular method.
  def generateSingularMethod(fn)
    "cobra::function_builder::build<&#{fn.fullyQualifiedName()}>(\"#{fn.name}\")"
  end

  # write the pre amble for a C++ file to [file]
  def writePreamble(file)
    Object.send(:writePreamble, file, "// ")
  end
end
