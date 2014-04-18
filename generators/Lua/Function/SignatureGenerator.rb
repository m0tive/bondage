
module Lua

  module Function

    class SignatureGenerator

      def self.generate(cls, fn, args, returnTypes)
        # Find the list of arguments with type then name, comma separated
        argString = formatArguments(args)

        # Find a list of return types, comma separated
        retString = formatReturnArguments(returnTypes)

        if (retString.length == 0)
          retString = "nil"
        end

        # Extract signature
        callConv = fn.static ? "." : ":"

        return "#{retString} #{cls.name}#{callConv}#{fn.name}(#{argString})"
      end

      def self.formatArguments(args)
        return args.length.times.map{ |i|
          arg = args[i]
          argName = arg.name.length != 0 ? arg.name : "arg#{i+1}"

          next "#{formatType(arg.type)} #{argName}"
        }.join(", ")
      end

      def self.formatReturnArguments(types)
        return types.map{ |t| formatType(t) }.join(", ")
      end

      # Format [type], a Type instance, in a way lua users can understand
      def self.formatType(type)
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
end