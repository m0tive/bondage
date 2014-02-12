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
	when :windows
		ENV["PATH"] = ENV["PATH"] + ";" + "..\\llvm-build\\Release+Asserts\\bin"
end

$:.unshift File.dirname(__FILE__) + "/../ffi-clang/lib"

def cleanLibrary(library)
	path = library.autogenPath
	if File.directory?(path)
		FileUtils.rm_rf(path)
	end
  FileUtils.mkdir_p(path)
end