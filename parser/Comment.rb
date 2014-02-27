class Command
  def initialize(name, text)
    @name = name
    @text = text
    @args = nil
  end

  attr_reader :name, :text, :args

  def setArgs(args)
    @args = args
  end

  def hasArg(arg)
    return args ? args.include?(arg) : false
  end
end

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
    return @commands[name] = Command.new(name, text)
  end

  # add a param command to the comment. [index] is the parameter index,
  # [text] is the brief for the param, [explicitDirection] is whether there was an
  # explicit in or out direction, and dir is that direction
  def addParam(index, text, explicitDirection, dir)
    return @params[index] = ParamComment.new(text, explicitDirection, dir)
  end

  # find if the comment has a command [name].
  def hasCommand(name)
    return @commands.has_key?(name)
  end

  # get the command text for the command [name].
  def commandText(name)
    command = @commands[name]
    return command ? @commands[name].text : ""
  end

  # get the command for the command [name].
  def command(name)
    return command = @commands[name]
  end

  def strippedCommand(name)
    if(hasCommand(name))
      return commandText(name).strip
    end
    return ""
  end

  # find a ParamCommand (or nil), for the param at [index].
  def paramforArgIndex(index)
    return @params[index]
  end
end