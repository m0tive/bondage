require 'fileutils'

# preamble helps us set up libclang, and ffi-clang. 
#ENV['LLVM_CONFIG'] = "../llvm-build/Release+Asserts/bin/llvm-config"
#ENV["PATH"] = ENV["PATH"] + ";" + Dir.getwd() + "/../bin"

$:.unshift File.dirname(__FILE__) + "/../ffi-clang/lib"

def cleanLibrary(library)
	path = library.autogenPath
	if File.directory?(path)
		FileUtils.rm_rf(path)
	end
  FileUtils.mkdir_p(path)
end