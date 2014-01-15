ENV["PATH"] = ENV["PATH"] + ";" + Dir.getwd() + "/bin"
require_relative "ffi/clang.rb"
require_relative "library.rb"
require_relative "visitor.rb"

class State
  def initialize(enter=nil, exit=nil)
    @onEnter = enter
    @onExit = exit
  end
  
  def enter(stack, cursor, parent)
    if(@onEnter)
      @onEnter.call(stack, cursor, parent)
    end
  end
  
  def exit(stack, cursor, parent)
    if(@onExit)
      @onExit.call(stack, cursor, parent)
    end
  end
end

class Parser
  def initialize(library)
    @index = FFI::Clang::Index.new
    
    sourceName = "DATA.cpp"
    
    args = [ "-fparse-all-comments", "/TC", sourceName ]
    
    library.includePaths.each do |path|
      args << "-I#{library.root}/#{path}"
    end
    
    source = "#define BINDER_PARSING\n"
    library.files.each do |file|
      source << "#include \"#{file}\"\n"
    end
    
    unsaved = FFI::Clang::UnsavedFile.new(sourceName, source)
    
    @translator = @index.parse_translation_unit(nil, args, [ unsaved ], [ :detailed_preprocessing_record, :include_brief_comments, :skip_function_bodies ])
    
    namespaceState = State.new(
      ->(stack, cursor, parent){ stack << :namespace },
      ->(stack, cursor, parent){ stack.pop } 
    )
      
    classState = State.new(
      ->(stack, cursor, parent){ stack << :class },
      ->(stack, cursor, parent){ stack.pop } 
    )
    
    accessSpecifierState = State.new(
    )
    
    fieldState = State.new(
      ->(stack, cursor, parent){ }
    )
    
    enumState = State.new(
      ->(stack, cursor, parent){ stack << :enum },
      ->(stack, cursor, parent){ stack.pop } 
    )
    
    enumMemberState = State.new(
      ->(stack, cursor, parent){ }
    )
      
    methodState = State.new(
      ->(stack, cursor, parent){ stack << :function },
      ->(stack, cursor, parent){ stack.pop } 
    )
    
    returnTypeState = State.new(
      ->(stack, cursor, parent){ }
    )
    
    paramState = State.new(
      ->(stack, cursor, parent){ stack << :param },
      ->(stack, cursor, parent){ stack.pop }
    )
    
    paramDefaultExprState = State.new(
      ->(stack, cursor, parent){ stack << :param_default_expr },
      ->(stack, cursor, parent){ stack.pop }
    )
    
    paramDefaultValueState = State.new(
    )
    
    functionBodyState = State.new()
    
    @@transitions = {
      # root of the file.
      :root => {
        :cursor_namespace => namespaceState,
      },
      # inside a namespace
      :namespace => {
        :cursor_class => classState,
      },
      # inside a class def
      :class => {
        :cursor_class => classState,
        :cursor_method => methodState,
        :cursor_field => fieldState,
        :cursor_enum => enumState,
        :cursor_access_specifier => accessSpecifierState,
      },
      :enum => {
        :cursor_enum_constant_decl => enumMemberState
      },
      # inside a function declaration
      :function => {
        :cursor_param_decl => paramState,
        :cursor_type_ref => returnTypeState,
        :cursor_compound_statement => functionBodyState,
      },
      # inside a function parameter declaration
      :param => {
        :cursor_unexposed_expr => paramDefaultExprState,
      },
      :param_default_expr => {
        :cursor_floating_literal => paramDefaultValueState
      }
    }
  end
  
  def parse(visitor)
    cursor = @translator.cursor
    
    @depth = 0
    
    stateStack = [ :root ]
    visitChildren(cursor, visitor, stateStack)
    
    raise "Incomplete source" unless (stateStack.size == 1 && stateStack[0] == :root)
  end
  
private
  def visitChildren(cursor, visitor, states)
    parent = nil
    
      
    cursor.visit_children do |cursor, parent|
      puts ('  ' * @depth) + "#{cursor.kind} #{cursor.spelling.inspect} #{cursor.raw_comment_text}"

      oldType = states[-1]
      transit = @@transitions[oldType][cursor.kind]
      
      raise "Unexpected transition #{oldType} -> #{cursor.kind}" unless transit
      
      
      transit.enter(states, cursor, parent)
      
      @depth = @depth + 1
      visitChildren(cursor, visitor, states)
      @depth = @depth - 1
      
      transit.exit(states, cursor, parent)
      
      next :continue
    end
    
  end

end
