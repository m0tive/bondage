require_relative "FunctionWrapperGenerator.rb"

module Lua

  class FunctionGenerator
    def initialize(classifiers, line, getter)
      @lineStart = line
      @getter = getter
      @wrapperGenerator = FunctionWrapperGenerator.new(classifiers, line, getter)
      reset()
    end

    attr_reader :docs, :name, :bind, :wrapper, :overloads, :bindIsForwarder

    def reset
      @bind = ""
      @signatures = []
      @docs = ""
      @name = ""
      @brief = ""
      @returnComment = ""
      @namedArgs = { }
      @argumentClassifiers = []
      @returnClassifiers = []
      @overloads = {}
      @anyClassifiersUsed = false
      @arguments = []
      @returnTypes = []
      @bindIsForwarder = false
    end

    # Generate the function, takes a [library], the owner [cls],
    # and a list of functions to generate for [fns]
    def generate(library, cls, fns)
      reset()

      FunctionVisitor.visit(cls, fns, self)

      @name = fns[0].name

      clsName = ""
      if (cls.kind_of?(ClassItem))
        clsName = cls.name
      end

      generateDocs()

      # If any classifiers are used, we need to generate a wrapper
      if (@anyClassifiersUsed)
        localName = "#{clsName}_#{@name}_wrapper"
        @bind = localName
        @bindIsForwarder = true
        @wrapper = @wrapperGenerator.generate(localName, library, clsName, @overloads, @argumentClassifiers, @returnClassifiers)
      else
        @bind = "#{@getter}(\"#{library.name}\", \"#{clsName}\", \"#{@name}\")"
        @wrapper = ""
      end
    end

    def visitFunction(owner, function, functionIndex, argCount)
      if (@brief.empty?)
        @brief = function.comment.strippedCommand("brief")
      end

      @arguments = []
      @returnTypes = []

      extractReturnData(function)

      ArgumentVisitor.visitFunction(owner, function, functionIndex, argCount, self)

      @signatures << generateSignature(owner, function, @arguments, @returnTypes)

      appendArgumentDataToOverloads(function, @arguments, @returnTypes)
    end

    def generateDocs()
      # format the signatures with the param comments to form the preable for a funtion.
      comment = @signatures.map{ |sig| "#{@lineStart}-- #{sig}" }.join("\n")

      commentLine = "\n#{@lineStart}-- "

      comment += "#{commentLine}\\brief #{@brief}"
      @namedArgs.to_a.sort.each do |argName, argBrief|
        if(!argName.empty? && !argBrief.empty?) 
          comment += "#{commentLine}\\param #{argName} #{argBrief.strip}"
        end
      end

      if(!@returnComment.empty?)
        comment += "#{commentLine}\\return #{@returnComment}"
      end

      @docs = comment
    end

    def generateSignature(cls, fn, args, returnTypes)
      # Find the list of arguments with type then name, comma separated
      argString = args.length.times.map{ |i|
        arg = args[i]
        argName = arg.name.length != 0 ? arg.name : "arg#{i+1}"

        next "#{formatType(arg.type)} #{argName}"
      }.join(", ")

      # Find a list of return types, comma separated
      retString = returnTypes.map{ |t| formatType(t) }.join(", ")

      if (retString.length == 0)
        retString = "nil"
      end

      # Extract signature
      callConv = fn.static ? "." : ":"

      return "#{retString} #{cls.name}#{callConv}#{fn.name}(#{argString})"
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

    def argumentClassifier(i)
      type = @argumentClassifiers[i]

      if (!type)
        return :none
      end

      return type
    end

    def extractReturnData(function)
      if (function.returnType)
        type, brief = extractArgumentClassifier(function.returnBrief, @returnClassifiers, 0)

        if (@returnComment.empty?)
          @returnComment = brief.strip
        end

        @returnTypes << function.returnType
      end
    end

    def appendArgumentDataToOverloads(function, arguments, returnTypes)
      overload = @overloads[arguments.length]
      if (!overload)
        overload = FunctionWrapperGenerator::ArgumentOverload.new
        overload.static = function.static
        @overloads[@arguments.length] = overload
      else
        if (overload.static != function.static)
          overload.static = :unknown
        end
      end

      overload.returnTypes << returnTypes
      overload.arguments << arguments
    end

    def returnClassifier(i)
      type = @returnClassifiers[i]

      if (!type)
        return :none
      end

      return type
    end

    def visitInputArgument(fn, n, argCount, arg)
      i = @arguments.length
      type, brief = extractArgumentClassifier(arg.brief, @argumentClassifiers, i)

      @arguments << arg

      visitArgument(arg, type, brief)
    end

    def visitOutputArgument(fn, n, argCount, arg)
      i = @returnTypes.length

      type, brief = extractArgumentClassifier(arg.brief, @returnClassifiers, i)

      @returnTypes << arg.type

      visitArgument(arg, type, brief)
    end

    def visitInputOutputArgument(fn, n, argCount, arg)
      visitInputArgument(fn, n, argCount, arg)
      visitOutputArgument(fn, n, argCount, arg)
    end

  private
    ARGUMENT_TYPE_REGEX = /\[([a-z]+)\]\s*(.*)/

    # Strip out an argument type from the brief text
    def extractArgumentClassifier(brief, arr, i)
      cutBrief = brief
      if (brief.strip.length == 0)
        return nil, ""
      end

      type = :none
      match = ARGUMENT_TYPE_REGEX.match(brief)
      if (match)
        type = match.captures[0].to_sym
        cutBrief = match.captures[1]
      end

      if (arr[i] && arr[i] != type)
        raise "Conflicting argument types #{type} and #{arr[i]} in #{brief}"
      end
      arr[i] = type

      @anyClassifiersUsed = @anyClassifiersUsed || type != :none

      return type, cutBrief
    end

    def visitArgument(arg, type, brief)
      if (!arg.name.empty? && !@namedArgs.include?(arg.name))
        @namedArgs[arg.name] = brief
      end
    end
  end
  
end