require 'fileutils'

require 'rbconfig'

def os
  @os ||= (
    host_os = RbConfig::CONFIG['host_os']
    case host_os
    when /mswin|msys|mingw|cygwin|bccwin|wince|emc/
      :windows
    when /darwin|mac os/
      :macosx
    when /linux/
      :linux
    when /solaris|bsd/
      :unix
    else
      raise Error::WebDriverError, "unknown os: #{host_os.inspect}"
    end
  )
end

# preamble helps us set up libclang, and ffi-clang. 
case os
  when :macosx
    ENV['LLVM_CONFIG'] = "../llvm-build/Release+Asserts/bin/llvm-config"
    PLATFORM_INCLUDES = [ "/usr/include/c++/4.2.1/" ]
  when :windows
    ENV["PATH"] = ENV["PATH"] + ";" + "..\\llvmTrunk-build\\Release\\bin"
    PLATFORM_INCLUDES = [ "..\\libc++\\include" ]
  when :linux
    PLATFORM_INCLUDES = [ "/usr/include/c++/4.6/", "/usr/include/c++/4.6/x86_64-linux-gnu/32/" ]
end

$:.unshift File.dirname(__FILE__) + "/../parser/ffi-clang/lib"

DEBUGGING = false

def setupLibrary(library)
  path = library.autogenPath(:cpp)
  FileUtils.mkdir_p(path)
  path = library.autogenPath(:lua)
  FileUtils.mkdir_p(path)
end

def exposeLibrary(lib, dbg = false)
  raise "Invalid library #{lib}" unless lib
  visitor = ParsedLibrary.parse(lib, PLATFORM_INCLUDES, [], DEBUGGING || dbg)

  return ClassExposer.new(visitor, DEBUGGING || dbg), visitor
end

def cleanLibrary(library)
  path = library.autogenPath(:cpp)
  if File.directory?(path)
    result = FileUtils.rm_rf(path)
  end

  path = library.autogenPath(:lua)
  if File.directory?(path)
    result = FileUtils.rm_rf(path)
  end
end

def runProcess(process, debug=false)
  output = `#{process}`

  if (debug)
    puts output
  end
  
  if (!$?.success? || $?.exitstatus != 0)
    raise output
  end
end

COPYRIGHT_MESSAGE = "Copyright me, fool. No, copying and stuff."
AUTOGEN_MESSAGE = "This file is auto generated, do not change it!"

class HeaderHelper
  def filePrefix(lang)

    lineStart = "//"
    if (lang == :lua)
      lineStart = "--"
    end

    return "#{lineStart} #{COPYRIGHT_MESSAGE}
#{lineStart}
#{lineStart} #{AUTOGEN_MESSAGE}
#{lineStart}"
  end

  def fileSuffix(lang)
    return ""
  end

  def requiredIncludes(lib)
    return []
  end

end