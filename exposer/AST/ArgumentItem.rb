
module AST
  
  class ArgumentItem
    def initialize(data, index, parent)
      @data = data
      @index = index
      @parent = parent
      @hasDefault = false

      setComment(@parent.comment.paramforArgIndex(index))
    end

    attr_reader :index, :brief, :hasDefault

    def name
      @data[:name]
    end

    def brief
      @brief
    end

    def input?
      @input
    end

    def output?
      @output
    end

    def type
      @data[:type]
    end

    def addParamDefault(data)
      @hasDefault = true
      return nil
    end

  private
    def setComment(comment)
      @input = true
      @output = false

      @brief = ""
      if (comment)
        @brief = comment.text

        if (comment.explicitDirection)
          case comment.direction
          when :pass_direction_in
            @input = true
            @output = false
          when :pass_direction_out
            @input = false
            @output = true
          when :pass_direction_inout
            @input = true
            @output = true
          end
        end
      end
    end
  end
end