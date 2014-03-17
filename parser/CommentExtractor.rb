EXTRA_COMMAND_TYPES = {
  "expose" => Set.new([
    "derivable",
    "copyable",
    "managed",
    "unmanaged"
  ])
}

class CommentExtractor
  def initialize()
    @commandPendingExtra = nil
  end

  
  # Extract a comment into [toFill] (a Comment), recursing into child comments
  def self.extract(comment, location)
    extractor = CommentExtractor.new
    toFill = Comment.new

    extractor.extractComment(toFill, comment, location)

    return toFill
  end

  def extractComment(toFill, comment, location)
    raise "invalid comment passed #{comment}" unless comment.kind_of?(FFI::Clang::Comment)

    if (comment.is_whitespace)
      return
    end

    if (comment.kind_of?(FFI::Clang::TextComment) ||
        comment.kind_of?(FFI::Clang::ParagraphComment))
      extractTextComment(toFill, comment, location)

    elsif (comment.kind_of?(FFI::Clang::BlockCommandComment))
      extractBlockCommandComment(toFill, comment, location)

    elsif (comment.kind_of?(FFI::Clang::InlineCommandComment))
      extractInlineCommandComment(toFill, comment, location)

    elsif (comment.kind_of?(FFI::Clang::ParamCommandComment))
      extractParamCommandComment(toFill, comment, location)
    end

    comment.each do |comment|
      extractComment(toFill, comment, location)
    end

    return comment
  end

  # Extract a text comment into [toFill]
  def extractTextComment(toFill, comment, location)
    if (@commandPendingExtra != nil)
      options = EXTRA_COMMAND_TYPES[@commandPendingExtra.name]

      flags = comment.text.split
      flags.each do |flag|
        if (!options.include?(flag))
          comment_error(location, "Invalid flag to command #{@commandPendingExtra.name} - #{flag}")
        end
      end

      @commandPendingExtra.setArgs(flags)

    elsif (toFill.commandText("brief") == "")
      toFill.addCommand("brief", comment.text)
    end
    @commandPendingExtra = nil
  end

  # Extract a block command comment - like /brief
  def extractBlockCommandComment(toFill, comment, location)
    @commandPendingExtra = nil
    toFill.addCommand(comment.name, comment.comment)
  end

  # Extract an inline command comment
  def extractInlineCommandComment(toFill, comment, location)
    @commandPendingExtra = nil
    command = toFill.addCommand(comment.name, "")

    if (EXTRA_COMMAND_TYPES[comment.name] != nil)
      @commandPendingExtra = command
    end
  end

  # Extract a param command comment like /param
  def extractParamCommandComment(toFill, comment, location)
    @commandPendingExtra = nil
    if(comment.valid_index?)
      toFill.addParam(comment.index, comment.comment, comment.direction_explicit?, comment.direction)
    end
  end

  def comment_error(loc, msg)
    raise "\n\nError, File: #{loc.start.file}, line: #{loc.start.line}, column: #{loc.start.column}: \n#{msg}"
  end
end