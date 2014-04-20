
module CPP

  module Helpers
    def self.generateWrapperText(lineStart, extraFnName, inArgs, initArgs, call, ret, resVar)
      ls = lineStart
      olLs = lineStart + "  "

      returnVal = ""
      if (resVar)
        returnVal = "\n#{olLs}return #{resVar};"
      end

      extra = ""
      if (initArgs.length != 0)
        extra = initArgs.join("\n#{olLs}") + "\n\n#{olLs}"
      end

      return "#{ls}#{ret} #{extraFnName}(#{inArgs})
#{ls}{
#{olLs}#{extra}#{call};#{returnVal}
#{ls}}"
    end


    def self.argType(arg)
      type = :value

      if (arg.isPointer)
        type = :pointer
      elsif (arg.isLValueReference)
        type = :reference
      end

      return type
    end

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

    class OutputArg
      def initialize(type, name)
        @type = type
        @name = name
      end

      attr_reader :type, :name
    end
  end
end