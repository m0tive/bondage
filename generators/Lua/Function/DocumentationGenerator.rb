module Lua

  class DocumentationGenerator

    def generateClass(lineStart, brief)
      return formatDocsTag(lineStart, 'brief', brief)
    end


    def generateFunction(lineStart, signatures, brief, returnBriefs, namedArgs)
      # format the signatures with the param comments to form the preable for a funtion.
      comment = signatures.map{ |sig| "#{lineStart}-- #{sig}" }.join("\n")

      comment += "\n" + formatDocsTag(lineStart, 'brief', brief)
      namedArgs.to_a.sort.each do |argName, argBrief|
        if(!argName.empty? && !argBrief.empty?) 
          comment += "\n" + formatDocsTag(lineStart, 'param', "#{argName} #{argBrief.strip}")
        end
      end

      primaryResult = returnBriefs[:result]

      if(primaryResult && !primaryResult.empty?)
        comment += "\n" + formatDocsTag(lineStart, 'return', primaryResult)
      end

      paramResults = returnBriefs.select{ |argName, argBrief| argName != :result}

      paramResults.to_a.sort.each do |argName, argBrief|
        if(argName.kind_of?(String) && (!argName.empty? && !argBrief.empty?))
          comment += "\n" + formatDocsTag(lineStart, 'param[out]', "#{argName} #{argBrief.strip}")
        end
      end

      return comment
    end

  private

    def formatDocsTag(lineStart, tagName, text)
      lines = text.strip.split("\n").map{ |t| t.strip }

      lines = lines.select{ |l|
        length = l.length
        if (l.length == 0)
          next true
        end

        firstChar = l[0]
        separatorLine = firstChar * length
        if (l == separatorLine)
          next false
        end

        next true
      }

      out = "#{lineStart}-- \\#{tagName} #{lines[0]}"

      if (lines.length <= 1)
        return out
      end

      return out + "\n" + (1..(lines.length-1)).map{ |i|
        "#{lineStart}-- #{lines[i]}"
      }.join("\n")
    end

  end
end