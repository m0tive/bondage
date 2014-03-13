require_relative "../exposer/ExposeAst.rb"
require_relative "GeneratorHelper.rb"
require_relative "../exposer/FunctionVisitor.rb"

class FunctionWrapperGenerator
  class WrapperArg
    def initialize(type, source, inoutExtra=nil, accessor="")
      @source = source
      @type = type
      @inoutSource = inoutExtra
      @inputType = accessor
    end

    attr_reader :type, :source, :inoutSource

    def callAccessor
      if (@inputType == :pointer)
        return "&"
      end
      return ""
    end

    def dataAccessor
      if (@inputType == :pointer)
        return "*"
      end
      return ""
    end
  end

  def generateCall(ls, owner, function, functionIndex, argCount, calls, extraFunctions)
    @lineStart = ls
    @needsWrapper = argCount != function.arguments.length
    @functionWrapper = nil
    @callArgs = []
    @owner = owner
    @function = function
    @functionIndex = functionIndex
    @name = function.name
    @inputArguments = []
    @outputArguments = []
    @returnType = nil

    if (!function.static)
      @inputArguments << "#{owner.fullyQualifiedName} &"
    end

    if (function.returnType)
      @outputArguments << function.returnType.name
    end

    # visit arguments of function.
    ArgumentVisitor.visitFunction(owner, function, functionIndex, argCount, self)

    if (@needsWrapper)
      accessor = functionAccessor()
      ret = returnType()
      extraFnName = literalName()
      resVar = resultName()

      inArgs = @inputArguments.each_with_index.map{ |arg, i| "#{arg} #{inputArgName(i)}" }.join(', ')

      initArgs = []
      if (@outputArguments.length > 1 || (@outputArguments.length > 0 && !@function.returnType))
        initArgs << "#{ret} #{resVar};"
      end

      ls = @lineStart
      olLs = @lineStart + "  "

      call = @callArgs.map do |arg|
        if (arg.type == :input)
          next arg.callAccessor + inputArgPassThrough(arg.source)
        elsif (arg.type == :output)
          next arg.callAccessor + outputArgReference(arg.source)
        elsif (arg.type == :inout)
          input = inputArgPassThrough(arg.inoutSource)
          output = outputArgReference(arg.source)
          initArgs << "#{output} = #{arg.dataAccessor} #{input};"
          next arg.callAccessor + output
        else
          raise "invalid arg type #{arg.type}"
        end
      end

      call = "#{accessor}(#{call.join(', ')});"
      returnExtra = ""
      if (@function.returnType)
        if (@outputArguments.length > 1)
          call = "#{outputArgReference(0)} = #{call}"
        else
          call = "auto &&#{resVar} = #{call}"
        end
      end

      if (@outputArguments.length > 0)
        returnExtra = "\n#{olLs}return #{resVar};"
      end

      sig = signature()
      callType = @function.static ? "build_call" : "build_member_standin_call"
      calls << "cobra::function_builder::#{callType}<#{sig}, &#{extraFnName}>"

      extra = ""
      if (initArgs.length != 0)
        extra = initArgs.join("\n") + "\n\n"
      end

      extraFunctions << 
"#{ls}#{ret} #{extraFnName}(#{inArgs})
#{ls}{
#{olLs}#{extra}#{call}#{returnExtra}
#{ls}}"

    else
      sig = signature()
      calls << "cobra::function_builder::build_call<#{sig}, &#{@function.fullyQualifiedName}>"

    end
  end

  def visitInputOutputArgument(fn, idx, cnt, arg)
    outIdx, access = addOutputArgumentHelper(arg)

    inIdx = @inputArguments.length
    @inputArguments << arg.type.name
    @callArgs << WrapperArg.new(:inout, outIdx, inIdx, access)
    @needsWrapper = true
  end
  
  def visitInputArgument(fn, idx, cnt, arg)
    inIdx = @inputArguments.length
    @inputArguments << arg.type.name
    @callArgs << WrapperArg.new(:input, inIdx)
  end

  def visitOutputArgument(fn, idx, cnt, arg)
    outIdx, access = addOutputArgumentHelper(arg)

    @callArgs << WrapperArg.new(:output, outIdx, nil, access)
    @needsWrapper = true
  end

private
  def addOutputArgumentHelper(arg)
    outIdx = @outputArguments.length
    name = arg.type.name
    accessor = ""

    if (arg.type.isPointer)
      accessor = :pointer
      name = arg.type.pointeeType().name
    elsif (arg.type.isLValueReference)
      name = arg.type.pointeeType().name
    elsif (arg.type.isRValueReference)
      raise "R value reference as an output? this needs some thought."
    end
    @outputArguments << name

    return outIdx, accessor
  end

  def signature()

    result = returnType()

    ptrType = "(*)"
    types = nil
    if (@needsWrapper)
      types = @inputArguments.join(", ")
    else
      types = @function.arguments.map{ |arg| arg.type.name }.join(", ")
      if (!@function.static)
        ptrType = "(#{@owner.fullyQualifiedName}::*)"
      end
    end

    return "#{result}#{ptrType}(#{types})"
  end

  def inputArgName(i)
    return "inputArg#{i}"
  end

  def inputArgPassThrough(i)
    type = @inputArguments[i]
    return "std::forward<#{type}>(#{inputArgName(i)})"
  end

  def outputArgReference(i)
    if (@outputArguments.length > 1)
      return "std::tuple::get<#{i}>(#{resultName()})"
    end

    return resultName()
  end

  def resultName
    return "result"
  end

  def functionAccessor
    if (!@function.static)
      return "#{inputArgName(0)}.#{@function.name}"
    end

    return @function.fullyQualifiedName
  end
  def returnType
    if (@outputArguments.length == 0)
      return "void"
    elsif (@outputArguments.length == 1)
      return @outputArguments[0]
    end

    return "std::tuple<#{@outputArguments.join(', ')}>"
  end

  def literalName
    fullyQualified = @function.fullyQualifiedName()
    literalName = fullyQualified.sub("::", "").gsub("::", "_")
    if (@functionIndex)
      literalName += "_overload#{@functionIndex}"
    end
    return literalName
  end
end

class FunctionGenerator
  def initialize(lineStart)
    @lineStart = lineStart
    reset()
    @wrapperGenerator = FunctionWrapperGenerator.new
  end

  attr_reader :bind, :extraFunctions

  def generateSimpleCall(sig, name)
    fnDef = generateBuildCall(name, sig, false)
    olLs = @lineStart + "  "
    @bind = "cobra::function_builder::build<
#{olLs}#{fnDef}
#{olLs}>"
  end

  def reset()
    @bind = ""
    @calls = []
    @extraFunctions = []
    @extraFunctionDecls = nil
  end

  def generate(owner, functions)
    reset()

    FunctionVisitor.visit(owner, functions, self)

    name = functions[0].name

    caller = "build"
    list = nil

    olLs = @lineStart + "  "

    if (@calls.length == 1)
      caller = "build"
      list = @calls[0]
    elsif(@calls.length > 1)
      caller = "build_overloaded"
      list = @calls.join(",\n#{olLs}")
    end


    @bind = 
"cobra::function_builder::#{caller}<
#{olLs}#{list}
#{olLs}>(\"#{name}\")"
  end

  def visitFunction(owner, function, functionIndex, argCount)
    @wrapperGenerator.generateCall(
      @lineStart,
      owner,
      function,
      functionIndex,
      argCount,
      @calls,
      @extraFunctions)
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
