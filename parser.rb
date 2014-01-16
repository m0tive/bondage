ENV['LLVM_CONFIG'] = "/Library/Developer/CommandLineTools/usr/lib/"
ENV["PATH"] = ENV["PATH"] + ";" + Dir.getwd() + "/bin"
require_relative "ffi/clang.rb"
require_relative "library.rb"
require_relative "visitor.rb"

class State
  def initialize(type, enter=nil)
    @type = type
  end
  
  def enter(states, data)
    states << @type
  end
  
  def exit(states, data)
    states.pop()
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
    
    namespaceState = State.new(:namespace, ->(parent, data){ parent.addNamespace(data) })
      
    classState = State.new(:class, ->(parent, data){ parent.addClass(data) })
    structState = State.new(:class, ->(parent, data){ parent.addStruct(data) })
    unionState = State.new(:class, ->(parent, data){ parent.addUnion(data) })

    classTemplateState = State.new(:class_template, ->(parent, data){ parent.addClassTemplate(data) })

    templateParamState = State.new(:param, ->(parent, data){ parent.addTemplateParam(data) })
    
    accessSpecifierState = State.new(:access_specifier, ->(parent, data){ parent.addAccessSpecifier(data) })
    
    fieldState = State.new(:field, ->(parent, data){ parent.addField(data) })
    
    enumState = State.new(:enum, ->(parent, data){ parent.addEnum(data) })
    
    enumMemberState = State.new(:enumMember, ->(parent, data){ parent.addEnumMember(data) })

    functionState = State.new(:function, ->(parent, data){ parent.addFunction(data) })

    functionTemplateState = State.new(:function_template, ->(parent, data){ parent.addFunctionTemplate(data) })
    
    returnTypeState = State.new(:return_type, ->(parent, data){ parent.addReturnType(data) })
    
    paramState = State.new(:param, ->(parent, data){ parent.addParam(data) })
    
    paramDefaultExprState = State.new(:param_default_expr)
    
    paramDefaultValueState = State.new(:param_default_value, ->(parent, data){ parent.addParamDefault(data) })
    
    functionBodyState = State.new(:function_body)
    
    @@transitions = {
      # root of the file.
      :root => {
        :cursor_namespace => namespaceState,
      },
      # inside a namespace
      :namespace => {
        :cursor_struct => structState,
        :cursor_class => classState,
        :cursor_function => functionState,
        :cursor_class_template => classTemplateState,
        :cursor_function_template => functionTemplateState,
      },
      # inside a class def
      :class => {
        :cursor_struct => structState,
        :cursor_class => classState,
        :cursor_union => unionState,
        :cursor_class_template => classTemplateState,
        :cursor_method => functionState,
        :cursor_function_template => functionTemplateState,
        :cursor_field => fieldState,
        :cursor_enum => enumState,
        :cursor_access_specifier => accessSpecifierState,
      },
      :class_template => {
        :cursor_class => classState,
        :cursor_class_template => classTemplateState,
        :cursor_template_type_param => templateParamState,
        :cursor_method => functionState,
        :cursor_function_template => functionTemplateState,
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
      :function_template => {
        :cursor_template_type_param => templateParamState,
        :cursor_type_ref => returnTypeState,
        :cursor_param_decl => paramState,
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
    data = [ ]
    visitChildren(cursor, visitor, stateStack, data)
    
    raise "Incomplete source" unless (stateStack.size == 1 && stateStack[0] == :root)
  end
  
private
  def visitChildren(cursor, visitor, states, data)
    parent = nil
    
      
    cursor.visit_children do |cursor, parent|
      puts ('  ' * @depth) + "#{cursor.kind} #{cursor.spelling.inspect} #{cursor.raw_comment_text}"

      oldType = states[-1]
      typeTransitions = @@transitions[oldType]
      raise "Unexpected child for #{oldType}, with child type #{cursor.kind}" unless typeTransitions

      transit = typeTransitions[cursor.kind]
      raise "Unexpected transition #{oldType} -> #{cursor.kind}" unless transit
      
      
      transit.enter(states, data)
      
      @depth = @depth + 1
      visitChildren(cursor, visitor, states, data)
      @depth = @depth - 1
      
      transit.exit(states, data)
      
      next :continue
    end
    
  end

end
