ENV["PATH"] = ENV["PATH"] + ";" + Dir.getwd() + "/bin"
require_relative "ffi/clang.rb"
require_relative "library.rb"
require_relative "visitor.rb"

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
    
    @translator = @index.parse_translation_unit(nil, args, [ unsaved ], [ :detailed_preprocessing_record, :include_brief_comments, :skip_function_bodies ])
  end
  
  def parse(visitor)
    cursor = @translator.cursor
    @depth = 0
    recurseInto(visitor, cursor)    
  end
  
private

  def recurseInto(visitor, cursor)
    cursor.visit_children do |cursor, parent|
      puts ('  ' * @depth) + "#{cursor.kind} #{cursor.spelling.inspect} #{cursor.raw_comment_text}"

      @depth = @depth + 1
      recurseInto(visitor, cursor)
      @depth = @depth - 1
      
      next :continue 
    end
  end

end
