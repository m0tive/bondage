
module Lua

  module Helper

    def self.generateRequires(resolver, exposer, clss)
      if (clss.length == 0)
        return ""
      end

      return clss.map{ |clsName|
        cls = exposer.allMetaData.findClass(clsName)
        "local #{cls.name} = require \"#{resolver.pathFor(cls)}\""
        }.join("\n") + "\n\n"
    end

  end
end