
module Lua

  class Properties
    def initialize()
    end

    def beginClass(lib, cls)
      @library = lib
      @cls = cls
      @properties = {}
      @getters = { }
      @setters = { }
    end

    PROPERTY_COMMAND = "property"

    def interestedInFunctions?(name, fns)

      fns.each do |fn|
        if (fn.comment.hasCommand(PROPERTY_COMMAND))
          return true
        end
      end

      return false
    end

    def addFunctions(name, fns, bind)
      propName = nil
      getter = false
      setter = false

      fns.each do |fn|
        if (fn.comment.hasCommand(PROPERTY_COMMAND))
          cmd = fn.comment.command(PROPERTY_COMMAND)
          propName = cmd.text.strip.split[0]

          if (fn.returnType != nil && fn.arguments.length == 0)
            getter = true
          end

          if (fn.arguments.length == 1)
            setter = true
          end
        end
      end

      raise "Invalid property #{@library.name}::#{@cls.name}::#{name}" unless (name && (getter or setter))

      source = @properties[propName]
      if (!source)
        source = []
        @properties[propName] = source
      end
      source << name

      if (getter)
        @getters[propName] = bind
      end

      if (setter)
        @setters[propName] = bind
      end
    end

    def formatAccess(map, n)
      el = map[n]
      if (!el)
        return "nil"
      end

      return el
    end

    def endClass(ls)

      orderedProperties = @properties.keys.sort

      propAccessors = orderedProperties.map do |name|
        sources = @properties[name]

        srcTag = "#{ls}-- \\sa " + sources.join(" ")

        "#{srcTag}\n#{name} = property(#{formatAccess(@getters, name)}, #{formatAccess(@setters, name)})"
      end
      propAccessorsJoined = propAccessors.join(",\n#{ls}")

      propNames = orderedProperties.map{ |p| "\"#{p}\"" }.join(",\n#{ls}  ")
      return "#{ls}properties = {
#{ls}  #{propNames}
#{ls}},

#{propAccessorsJoined}"
    end
  end

end