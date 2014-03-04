require_relative "../exposer/ExposeAst.rb"
require_relative "GeneratorHelper.rb"

class FunctionGenerator
  def initialize(lineStart)
    @lineStart = lineStart
    reset()
  end

  attr_reader :bind, :extraFunctions

  def reset()
    @bind = ""
    @extraFunctions = []
    @extraFunctionDecls = nil
  end

  def needsSpecialBinding(function)
    function.arguments.each do |arg|
      if (arg.hasDefault())
        return true
      end
    end
    return false
  end

  def generate(owner, functions)
    reset()

    if (functions.length == 1)
      function = functions[0]
      needsSpecial = needsSpecialBinding(function)

      if (!needsSpecial)
        return generateSimple(owner, function)
      else
        return generateArgumentOverloads(owner, function)
      end
    else
      return generateFunctionOverloads(owner, functions)
    end
  end

private
  def generateSimple(owner, fn)
    name, sig = generateArgumentOverload(owner, fn, fn.name, fn.arguments.length)
    
    sig = generateFunctionPointerSignature(owner, fn)
    @bind = "cobra::function_builder::build<#{sig}, &#{name}>(\"#{fn.name}\")"
  end

  def generateBuildCall(name, sig)
    return "cobra::function_builder::build_call<#{sig}, &#{name}>"
  end

  def generateFunctionOverloads(owner, fns)
    functionDefs = []
    name = nil
    fns.each_index do |i|
      fn = fns[i]
      functionDefs = functionDefs + expandArgumentOverloads(owner, fn, i)
      name = fn.name
    end

    return generateOverloadCalls(owner, functionDefs, name)
  end

  def expandArgumentOverloads(owner, fn, fnId=nil)
    fullyQualified = fn.fullyQualifiedName()
    literalName = fullyQualified.sub("::", "").gsub("::", "_")
    if (fnId)
      literalName += "_#{fnId}"
    end

    functionDefs = []
    fn.arguments.each_index do |i|
      arg = fn.arguments[i]
      if (arg.hasDefault)
        name, sig = generateArgumentOverload(owner, fn, literalName, i)
        functionDefs << generateBuildCall(name, sig)
      end
    end

    name, sig = generateArgumentOverload(owner, fn, literalName, fn.arguments.length)
    functionDefs << generateBuildCall(name, sig)
  end

  def generateArgumentOverloads(owner, fn)
    return generateOverloadCalls(owner, expandArgumentOverloads(owner, fn), fn.name)
  end

  def generateOverloadCalls(owner, functionDefs, name)
    olLs = @lineStart + "  "

    functions = functionDefs.join(",\n#{olLs}")

    @bind = 
"cobra::function_builder::build_overloaded<
#{olLs}#{functions}
#{olLs}>(\"#{name}\")"
  end

  def generateFunctionPointerSignature(owner, fn, argCountMax=nil, forceStatic=false)
    argTypes = ""

    argCount = argCountMax ? argCountMax : fn.arguments.length
    
    argCount.times do |n|
      arg = fn.arguments[n]
      if (n != 0)
        argTypes << ", "
      end

      argTypes << arg.type.name
    end

    returnType = "void"
    if (fn.returnType)
      returnType = fn.returnType.name
    end

    ptrType = "(*)"
    if (!fn.static && !forceStatic)
      ptrType = "(#{owner.fullyQualifiedName}::*)"
    end

    return "#{returnType}#{ptrType}(#{argTypes})"
  end

  def generateArgumentOverload(owner, fn, fnIdentifier, argCount)
    name = fn.fullyQualifiedName
    if (argCount != fn.arguments.length)
      args = ""
      argPassThrough = ""
      
      argCount.times do |n|
        arg = fn.arguments[n]
        if (n != 0)
          args << ", "
          argPassThrough << ", "
        end

        argName = "arg#{n}"
        argPassThrough << arg.type.name << " #{argName}"
        args << "std::forward<#{arg.type.name}>(#{argName})"
      end

      ls = @lineStart
      fnLs = @lineStart + "  "

      returnType = "void"
      name = "#{fnIdentifier}_overload#{argCount}"
      call = "#{fn.fullyQualifiedName}(#{args})"
      if (fn.returnType)
        returnType = fn.returnType.name
        body = 
"auto &&result = #{call};
#{fnLs}return result;"

      else
        body = "#{call};"
      end

      fnDef = 
"#{ls}#{returnType} #{name}(#{argPassThrough})
#{ls}{
#{fnLs}#{body}
}"

      @extraFunctions << fnDef
    end
    return name, generateFunctionPointerSignature(owner, fn, argCount)
  end
end

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

      toGenerate.fullTypes.each do |clsPath, cls|
        if(cls.type == :class)
          if(!cls.hasParentClass())
            file.write("COBRA_EXPOSED_CLASS(#{clsPath})\n")
          else
            file.write("COBRA_EXPOSED_DERIVED_CLASS(#{clsPath}, #{cls.parentClass})\n")
          end
        end
      end
    end

    # All exposed classes are dumped into one C++ file.
    File.open(dir + "/#{@library.name}.cpp", 'w') do |file|
      writePreamble(file)

      toGenerate.fullTypes.map{ |clsPath, cls| "#{generateClassData(cls)}\n" }.each { |data| file.write(data) }
    end
  end

private
  # Generate binding data for a class
  def generateClassData(cls)
    # parsed is the ExposeAst data for a class, which is not present in classes restored from JSON
    parsed = cls.parsed
    raise "Can't generate for restored class '#{cls.name}'" unless parsed

    # find a name that is a valid literal in c++ used for static definitions
    fullyQualified = parsed.fullyQualifiedName()
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

const cobra::function #{methodsLiteral}[] = #{generateMethodData(parsed)};

#{classInfo}

";


    return output
  end

  # Generate function exposure data for [cls]
  def generateMethodData(cls)
    functions = @exposer.findExposedFunctions(cls)

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
