# ParamComment wraps a parameter comment, and its direction data
class ParamComment
  def initialize(text, expDir, dir)
    @text = text
    @explicitDirection = expDir
    @direction = dir
  end

  attr_reader :text, :explicitDirection, :direction
end

# Comment wraps a comment section in code, and any commands/param commands provided.
class Comment
  def initialize()
    @commands = {}
    @params = []
  end

  # add a simple command to the comment. [name] is the command, [text] the command text.
  def addCommand(name, text)
    @commands[name] = text
  end

  # add a param command to the comment. [index] is the parameter index,
  # [text] is the brief for the param, [explicitDirection] is whether there was an
  # explicit in or out direction, and dir is that direction
  def addParam(index, text, explicitDirection, dir)
    @params[index] = ParamComment.new(text, explicitDirection, dir)
  end

  # find if the comment has a command [name].
  def hasCommand(name)
    return @commands.has_key?(name)
  end

  # get the command text for the command [name].
  def command(name)
    return @commands[name]
  end

  def strippedCommand(name)
    if(hasCommand(name))
      return command(name).strip
    end
    return ""
  end

  # find a ParamCommand (or nil), for the param at [index].
  def paramforArgIndex(index)
    return @params[index]
  end
end