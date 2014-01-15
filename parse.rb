ENV["PATH"] = ENV["PATH"] + ";" + Dir.getwd() + "/bin"
require "ffi/clang.rb"

class Library
  def initialize(name, path)
    @name = name
    @root = path
    @includePaths = []
    @files = []
  end
  
  attr_reader :files, :includePaths, :root
  
  def addFile(path)
    @files << path
  end
  
  
  def addIncludePath(path)
    @includePaths << path
  end
end

class Visitor
end

class Parser
  def initialize(library)
    @index = FFI::Clang::Index.new
    
    sourceName = "DATA.cpp"
    
    args = [ "-fparse-all-comments", "/TC", sourceName ]
    
    library.includePaths.each do |path|
      args << "-I#{library.root}/#{path}"
    end
    
    source = ""
    library.files.each do |file|
      source << "#include \"#{file}\"\n"
    end
    
    unsaved = FFI::Clang::UnsavedFile.new(sourceName, source)
    
    puts args
    
    @translator = @index.parse_translation_unit(nil, args, [ unsaved ], [ :detailed_preprocessing_record, :include_brief_comments, :skip_function_bodies ])
  end
  
  def parse(visitor)
    cursor = @translator.cursor
    cursor.visit_children do |cursor, parent|
      puts "#{cursor.kind} #{cursor.spelling.inspect}"
      
      puts "#{cursor.declaration?} #{cursor.comment.kind}, #{cursor.raw_comment_text}"

      next :recurse 
    end
  end
end

class VisitorImpl < Visitor

end 

library = Library.new("test", "test")
library.addIncludePath(".")
library.addFile("test.h")

parser = Parser.new(library)

visitor = VisitorImpl.new
parser.parse(visitor)

#index = FFI::Clang::Index.new
#translation_unit = index.parse_translation_unit(nil, [ "-fparse-all-comments", "/TC", "-Itest", "DATA.cpp" ], [ unsaved ], [ :detailed_preprocessing_record, :include_brief_comments, :skip_function_bodies ])
