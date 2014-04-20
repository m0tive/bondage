require_relative "../../exposer/ExposeAst.rb"


module Lua

  # Generate lua exposing code for C++ enums
  class EnumGenerator
    def initialize(lineStart)
      @lineStart = lineStart
    end

    attr_reader :enums

    def reset
      @enums = []
    end

    def generate(owner, exposer)
      reset()

      owner.enums.each do |name, enum|
        if (name.empty? || 
          !exposer.allMetaData.isExposedEnum?(enum.fullyQualifiedName))
          next
        end

        str = "{\n"
        enum.members.each do |k, v|
          str << "#{@lineStart}  #{k} = #{v},\n"
        end
        str << "#{@lineStart}}"

        @enums << "#{@lineStart}#{name} = #{str}"
      end
    end

  end

end