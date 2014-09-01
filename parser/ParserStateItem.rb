require_relative "CommentExtractor.rb"

module Parser

  EMPTY_COMMENT = Comment.new

  class ParserStateItem
    def initialize(type, enter=nil)
      @type = type
      @onEnter = enter
    end

    def enter(parser, states, data, cursor)
      states << @type

      newInfo = buildData(parser, cursor)

      newData = nil
      if (@onEnter && data[-1])
        newData = @onEnter.call(data[-1], newInfo)
      end

      data << newData

      return newData != nil
    end

    def exit(parser, states, data)
      states.pop()
      data.pop()
    end

  private
    def buildData(parser, cursor)
      comment = EMPTY_COMMENT
      if(cursor.comment_range.start.file != nil)
        comment = CommentExtractor.extract(
          cursor.comment,
          cursor.raw_comment_text,
          cursor.comment_range,
          parser.debug)
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
  end
end