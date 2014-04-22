require_relative "WrapperGenerator.rb"
require_relative "SignatureGenerator.rb"
require_relative "DocumentationGenerator.rb"

module Lua

  module Function

    class Generator
      def initialize(classifiers, externalLine, line, getter)
        @lineStart = line
        @getter = getter
        @wrapperGenerator = WrapperGenerator.new(classifiers, externalLine, getter)
        reset()
      end

      attr_reader :docs, :name, :bind, :wrapper, :overloads, :bindIsForwarder

      def reset
        @bind = ""
        @signatures = Set.new()
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
      def generate(library, cls, fns, requiredClasses)
        reset()

        FunctionVisitor.visit(cls, fns, self)

        @name = fns[0].name

        clsName = ""
        if (cls.kind_of?(AST::ClassItem))
          clsName = cls.name
        end

        @docs = DocumentationGenerator.generate(@lineStart, @signatures, @brief, @returnComment, @namedArgs)

        # If any classifiers are used, we need to generate a wrapper
        if (@anyClassifiersUsed)
          localName = "#{clsName}_#{@name}_wrapper"
          @bind = localName
          @bindIsForwarder = true
          @wrapper = @wrapperGenerator.generate(localName, library, clsName, @overloads, @argumentClassifiers, @returnClassifiers, requiredClasses)
        else
          @bind = "#{@getter}(\"#{library.name}\", \"#{clsName}\", \"#{@name}\")"
          @wrapper = ""
        end
      end

      def visitFunction(owner, function, functionIndex, argCount)
        if (@brief.empty?)
          @brief = function.comment.commandText("brief")
        end

        @arguments = []
        @returnTypes = []

        extractReturnData(function)

        ArgumentVisitor.visitFunction(owner, function, functionIndex, argCount, self)

        @signatures << SignatureGenerator.generate(owner, function, @arguments, @returnTypes)

        appendArgumentDataToOverloads(function, @arguments, @returnTypes)
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
          overload = WrapperGenerator::ArgumentOverload.new
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
end