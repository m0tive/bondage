require_relative "../CommentHelper.rb"

module Lua

  module Function

    class DocumentationGenerator

      def self.generate(lineStart, signatures, brief, returnBriefs, namedArgs)
        # format the signatures with the param comments to form the preable for a funtion.
        comment = signatures.map{ |sig| "#{lineStart}-- #{sig}" }.join("\n")

        comment += "\n" + Helper::formatDocsTag(lineStart, 'brief', brief)
        namedArgs.to_a.sort.each do |argName, argBrief|
          if(!argName.empty? && !argBrief.empty?) 
            comment += "\n" + Helper::formatDocsTag(lineStart, 'param', "#{argName} #{argBrief.strip}")
          end
        end

        primaryResult = returnBriefs[:result]

        if(primaryResult && !primaryResult.empty?)
          comment += "\n" + Helper::formatDocsTag(lineStart, 'return', primaryResult)
        end

        paramResults = returnBriefs.select{ |argName, argBrief| argName != :result}

        paramResults.to_a.sort.each do |argName, argBrief|
          if(argName.kind_of?(String) && (!argName.empty? && !argBrief.empty?))
            comment += "\n" + Helper::formatDocsTag(lineStart, 'param[out]', "#{argName} #{argBrief.strip}")
          end
        end

        return comment
      end
    end
  end
end