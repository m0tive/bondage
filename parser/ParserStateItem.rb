class ParserStateItem
  def initialize(type, enter=nil)
    @type = type
    @onEnter = enter
  end

  def enter(states, data, cursor)
    states << @type

    newInfo = buildData(cursor)

    newData = nil
    if (@onEnter && data[-1])
      newData = @onEnter.call(data[-1], newInfo)
    end

    data << newData

    return newData != nil
  end

  def exit(states, data)
    states.pop()
    data.pop()
  end

private
  def buildData(cursor)
    comment = Comment.new
    if(cursor.comment_range.start.file != nil)
      extractComment(comment, cursor.comment)
    end

    type = nil
    if(cursor.type.kind != :type_invalid)
      type = Type.new(cursor.type)
    end


    return {
      :name => cursor.spelling,
      :cursor => cursor,
      :type => type,
      :comment => comment,
      :accessSpecifier => cursor.access_specifier
    }
  end

  # Extract a comment into [toFill] (a Comment), recursing into child comments
  def extractComment(toFill, comment)
    raise "invalid comment passed #{comment}" unless comment.kind_of?(FFI::Clang::Comment)

    if(comment.kind_of?(FFI::Clang::TextComment) || comment.kind_of?(FFI::Clang::ParagraphComment))
      extractTextComment(toFill, comment)

    elsif(comment.kind_of?(FFI::Clang::BlockCommandComment))
      extractBlockCommandComment(toFill, comment)

    elsif(comment.kind_of?(FFI::Clang::InlineCommandComment))
      extractInlineCommandComment(toFill, comment)

    elsif(comment.kind_of?(FFI::Clang::ParamCommandComment))
      extractParamCommandComment(toFill, comment)
    end

    comment.each do |comment|
      extractComment(toFill, comment)
    end

    return comment
  end

  # Extract a text comment into [toFill]
  def extractTextComment(toFill, comment)
    if(toFill.command("brief") == "")
      toFill.addCommand("brief", comment.text)
    end
  end

  # Extract a block command comment - like /brief
  def extractBlockCommandComment(toFill, comment)
    toFill.addCommand(comment.name, comment.comment)
  end

  # Extract an inline command comment
  def extractInlineCommandComment(toFill, comment)
    toFill.addCommand(comment.name, "")
  end

  # Extract a param command comment like /param
  def extractParamCommandComment(toFill, comment)
    if(comment.valid_index?)
      toFill.addParam(comment.index, comment.comment, comment.direction_explicit?, comment.direction)
    end
  end
end