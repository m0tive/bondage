
module Lua

  module Helper

    def self.formatDocsTag(lineStart, tagName, text)
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

      puts out

      return out
    end

  end
end