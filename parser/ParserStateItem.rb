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

  def extractComment(toFill, comment)
    if(comment.kind_of?(FFI::Clang::Comment))
      if(comment.kind_of?(FFI::Clang::TextComment) || comment.kind_of?(FFI::Clang::ParagraphComment))
        if(toFill.command("brief") == "")
          toFill.addCommand("brief", comment.text)
        end
      elsif(comment.kind_of?(FFI::Clang::BlockCommandComment))
        toFill.addCommand(comment.name, comment.comment)
      elsif(comment.kind_of?(FFI::Clang::InlineCommandComment))
        toFill.addCommand(comment.name, "")
      elsif(comment.kind_of?(FFI::Clang::ParamCommandComment))
        if(comment.valid_index?)
          toFill.addParam(comment.index, comment.comment, comment.direction_explicit?, comment.direction)
        end
      end

      comment.each do |comment|
        extractComment(toFill, comment)
      end
    end

    return comment
  end
end