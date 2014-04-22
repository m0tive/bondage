require_relative "../CommentHelper.rb"

module Lua

  module Function

    class DocumentationGenerator

      def self.generate(lineStart, signatures, brief, returnBrief, namedArgs)
        # format the signatures with the param comments to form the preable for a funtion.
        comment = signatures.map{ |sig| "#{lineStart}-- #{sig}" }.join("\n")

        comment += "\n" + Helper::formatDocsTag(lineStart, 'brief', brief)
        namedArgs.to_a.sort.each do |argName, argBrief|
          if(!argName.empty? && !argBrief.empty?) 
            comment += "\n" + Helper::formatDocsTag(lineStart, 'param', "#{argName} #{argBrief.strip}")
          end
        end

        if(!returnBrief.empty?)
          comment += "\n" + Helper::formatDocsTag(lineStart, 'return', returnBrief)
        end

        return comment
      end
    end
  end
end