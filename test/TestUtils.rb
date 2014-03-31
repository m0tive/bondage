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
  path = library.autogenPath
  FileUtils.mkdir_p(path)
end

def exposeLibrary(lib, dbg = false)
  parser = Parser.new(lib, PLATFORM_INCLUDES, [], DEBUGGING || dbg)
  visitor = ExposeAstVisitor.new(lib)
  parser.parse(visitor)
  return Exposer.new(visitor, DEBUGGING || dbg), visitor
end

def cleanLibrary(library)
  path = library.autogenPath
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