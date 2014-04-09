

module Lua

  class FunctionGenerator
    def initialize(line, getter)
      @lineStart = line
      @getter = getter
      reset()
    end

    attr_reader :docs, :classDefinition

    def reset
      @classDefinition = ""
      @signatures = []
      @docs = ""
      @name = ""
      @brief = ""
      @returnComment = ""
      @namedArgs = { }
    end

    def generate(library, cls, fns)
      reset()

      FunctionVisitor.visit(cls, fns, self)

      @name = fns[0].name

      @classDefinition = "#{@name} = #{@getter}(\"#{library.name}\", \"#{@name}\")"
      generateDocs()
    end

    def visitFunction(owner, function, functionIndex, argCount)
      @signatures <<  generateSignature(owner, function, argCount)

      if (@brief.empty?)
        @brief = function.comment.strippedCommand("brief")
      end
      if (@returnComment.empty?)
        @returnComment = function.returnBrief.strip
      end

      argCount.times do |i|
        arg = function.arguments[i]
        if (!arg.name.empty? && !@namedArgs.include?(arg.name))
          @namedArgs[arg.name] = arg
        end
      end
    end

    def generateDocs()
      # format the signatures with the param comments to form the preable for a funtion.
      comment = @signatures.map{ |sig| "#{@lineStart}-- #{sig}" }.join("\n")

      commentLine = "\n#{@lineStart}-- "

      comment += "#{commentLine}\\brief #{@brief}"
      @namedArgs.to_a.sort.each do |argName, arg|
        if(!argName.empty? && !arg.brief.empty?)
          comment += "#{commentLine}\\param #{argName} #{arg.brief.strip}"
        end
      end

      if(!@returnComment.empty?)
        comment += "#{commentLine}\\return #{@returnComment}"
      end

      @docs = comment
    end

    def generateSignature(cls, fn, argCount)
      name = fn.name

      # extract signature
      callConv = fn.static ? "." : ":"

      argString = argCount.times.map{ |i|
        arg = fn.arguments[i]
        argName = arg.name 
        if (argName == "")
          argName = "arg#{i}"
        end
        "#{formatType(arg.type)} #{argName}"
      }.join(", ")

      return "#{formatType(fn.returnType)} #{cls.name}#{callConv}#{name}(#{argString})"
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
  end

end