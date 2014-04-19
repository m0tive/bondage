require "set"

EXTRA_COMMAND_TYPES = {
  "expose" => Set.new([
    "derivable",
    "copyable",
    "managed",
    "unmanaged"
  ]),
  "property" => nil,
}

class CommentExtractor
  def initialize(debug)
    @regExpCache = { }
    @debug = debug
    @level = 0
  end

  
  # Extract a comment into [toFill] (a Comment), recursing into child comments
  def self.extract(comment, rawText, location, debug)
    extractor = CommentExtractor.new(debug)
    toFill = Comment.new

    extractor.extractComment(toFill, comment, location)

    extractor.extractExtraData(toFill, rawText, location)

    return toFill
  end

  def extractExtraData(comment, text, location)
    EXTRA_COMMAND_TYPES.each do |cmd, allowedOpts|
      if (comment.hasCommand(cmd) && allowedOpts)

        options = extractExtraCommandWithOptions(text, cmd, allowedOpts)
        if (!options)
          next
        end

        command = comment.command(cmd)
        command.setArgs(options)
      end
    end
  end

  def extractExtraCommandWithOptions(text, cmd, allowedOpts)
    commandRegex = @regExpCache[cmd]
    if (!commandRegex)
      commandRegex = /\\#{cmd} (.*)$/
      @regExpCache[cmd] = commandRegex
    end

    match = commandRegex.match(text)
    if (!match)
      return nil
    end

    if (@debug)
      puts "#{debugPadd}SPECIAL\t#{cmd}"
    end

    options = match.captures[0].split

    if (allowedOpts)
      options.each do |flag|
        if (!allowedOpts.include?(flag))
          comment_error(location, "Invalid flag to command #{cmd} - #{flag}")
        end
      end
    end

    return options
  end

  def extractComment(toFill, comment, location)
    if (!comment)
      if (@debug)
        puts "#{debugPadd}COMMENT\tnil"
      end
      return
    end

    if (@debug)
      puts "#{debugPadd}COMMENT\t#{comment} [#{comment.num_children}]"
    end

    raise "invalid comment passed #{comment}" unless comment.kind_of?(FFI::Clang::Comment)

    if (comment.is_whitespace)
      if (@debug)
        puts "#{debugPadd(1)}IGNORE\t[whitespace]"
      end
      return
    end

    extractCommandData(toFill, comment, location)

    extractChildComments(toFill, comment, location)

    return comment
  end

  def extractCommandData(toFill, comment, location)
    if (comment.kind_of?(FFI::Clang::TextComment) ||
        comment.kind_of?(FFI::Clang::ParagraphComment))
      extractTextComment(toFill, comment, location)

    elsif (comment.kind_of?(FFI::Clang::VerbatimLine))
      extractVerbatimLineComment(toFill, comment, location)

    elsif (comment.kind_of?(FFI::Clang::BlockCommandComment))
      extractBlockCommandComment(toFill, comment, location)

    elsif (comment.kind_of?(FFI::Clang::InlineCommandComment))
      extractInlineCommandComment(toFill, comment, location)

    elsif (comment.kind_of?(FFI::Clang::ParamCommandComment))
      extractParamCommandComment(toFill, comment, location)
    end
  end

  def extractChildComments(toFill, comment, location)
    @level += 1
    index = 1
    comment.each do |child|
      if (@debug)
        puts "#{debugPadd}CHILD\t[#{index}/#{comment.num_children}]"
      end
      extractComment(toFill, child, location)
      index += 1
    end
    @level -= 1
  end

  # Extract a text comment into [toFill]
  def extractTextComment(toFill, comment, location)
    if (@debug)
      puts "#{debugPadd(1)}TEXT\t#{comment.text.strip}"
    end

    if (toFill.commandText("brief") == "")
      toFill.addCommand("brief", comment.text)
    end
  end

  # Extract a block command comment - like /brief
  def extractBlockCommandComment(toFill, comment, location)
    if (@debug)
      puts "#{debugPadd(1)}BLOCK\t#{comment.name} #{comment.comment.strip}"
    end
    toFill.addCommand(comment.name, comment.comment)
  end

  # Extract an inline command comment
  def extractInlineCommandComment(toFill, comment, location)
    if (@debug)
      puts "#{debugPadd(1)}INLINE\t#{comment.name.strip}"
    end
    command = toFill.addCommand(comment.name, "")
  end

  def extractVerbatimLineComment(toFill, comment, location)

    if (@debug)
      puts "#{debugPadd(1)}VERBATIM\t#{comment.name} - #{comment.text.strip}"
    end

    command = toFill.addCommand(comment.name, comment.text)
  end

  # Extract a param command comment like /param
  def extractParamCommandComment(toFill, comment, location)
    cmt = comment.comment
    if (@debug)
      puts "#{debugPadd(1)}PARAM\t#{comment.index} #{cmt.strip}"
    end
    @commandPendingExtra = nil
    if(comment.valid_index?)
      toFill.addParam(comment.index, cmt, comment.direction_explicit?, comment.direction)
    end
  end

  def debugPadd(extra=0)
    return '  ' * (@level+extra)
  end

  def comment_error(loc, msg)
    raise "\n\nError, File: #{loc.start.file}, line: #{loc.start.line}, column: #{loc.start.column}: \n#{msg}"
  end
end