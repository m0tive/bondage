    ENV['LLVM_CONFIG'] = "../llvm-build/Release+Asserts/bin/llvm-config"
ENV["PATH"] = ENV["PATH"] + ";" + Dir.getwd() + "/bin"

$:.unshift File.dirname(__FILE__) + "/ffi-clang/lib"
require "ffi/clang.rb"

require_relative "library.rb"
require_relative "visitor.rb"

class Comment
  def initialize()
    @commands = {}
    @params = {}
  end

  def addCommand(name, text)
    @commands[name] = text
  end

  def addParam(name, text)
    @params[name] = text
  end

  def hasCommand(name)
    return @commands.has_key?(name)
  end

  def command(name)
    return @commands[name]
  end

  def param(name)
    return @params[name]
  end
end

class Type
  def initialize(type)
    @type = type
    @canonical = type.canonical
  end

  def isBasicType
    if(@canonical.kind != :type_invalid &&
       @canonical.kind != :type_unexposed &&
       @canonical.kind <= :type_longdouble)
      return true
    end
    return false
  end

  def isPointer
    return @canonical.kind == :type_pointer
  end

  def isLValueReference
    return @canonical.kind == :type_lvalue_ref
  end

  def isRValueReference
    return @canonical.kind == :type_rvalue_ref
  end

  def pointeeType
    return Type.new(@canonical.pointee)
  end

  def description
    return "#{@canonical.spelling} #{@canonical.kind}"
  end
end

class StateData
  def initialize(userData=nil)
    @userData = userData
  end
  
  attr_reader :userData
end

class State
  def initialize(type, enter=nil)
    @type = type
    @onEnter = enter
  end
  
  def enter(states, data, cursor)
    states << @type
    
    newInfo = buildData(cursor)
    
    newData = nil
    if (@onEnter && data[-1].userData)
      newData = @onEnter.call(data[-1].userData, newInfo)
    end
    
    data << StateData.new(newData)
    
    return newData != nil
  end
  
  def exit(states, data)
    states.pop()
    data.pop()
  end
  
private
  def buildData(cursor)
    comment = Comment.new
    extractComment(comment, cursor.comment)
    
    type = nil
    if(cursor.type.kind != :type_invalid)
      type = Type.new(cursor.type)
    end


    return {
      :name => cursor.spelling,
      :type => type,
      :comment => comment
    }
  end

  def extractComment(toFill, comment)
    if(comment.kind_of?(FFI::Clang::Comment))
      if(comment.kind_of?(FFI::Clang::TextComment) || comment.kind_of?(FFI::Clang::ParagraphComment))
        if(toFill.command("brief") == "")
          toFill.addCommand("brief", comment.text)
        end
      elsif(comment.kind_of?(FFI::Clang::BlockCommandComment))
        toFill.addCommand(comment.name, comment.comment)
      elsif(comment.kind_of?(FFI::Clang::InlineCommandComment))
        toFill.addCommand(comment.name, "")
      elsif(comment.kind_of?(FFI::Clang::ParamCommandComment))
        toFill.addParam(comment.name, comment.comment)
      end
      
      comment.each do |comment|
        extractComment(toFill, comment)
      end
    end

    return comment
  end
end

class Parser
  def initialize(library)
    @debug = false
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

    classConstructor = State.new(:function, ->(parent, data){ parent.addConstructor(data) })
    classDestructor = State.new(:destructor)
    
    superClassState = State.new(:base_class)
    
    superClassTypeState = State.new(:base_class_type)
    
    classTemplateState = State.new(:class, ->(parent, data){ parent.addClassTemplate(data) })

    templateParamState = State.new(:param, ->(parent, data){ parent.addTemplateParam(data) })
    
    accessSpecifierState = State.new(:access_specifier, ->(parent, data){ parent.addAccessSpecifier(data) })
    
    fieldState = State.new(:field, ->(parent, data){ parent.addField(data) })
    
    enumState = State.new(:enum, ->(parent, data){ parent.addEnum(data) })
    
    enumMemberState = State.new(:enumMember, ->(parent, data){ parent.addEnumMember(data) })

    functionState = State.new(:function, ->(parent, data){ parent.addFunction(data) })

    functionTemplateState = State.new(:function_template, ->(parent, data){ parent.addFunctionTemplate(data) })
    
    returnTypeState = State.new(:return_type, ->(parent, data){ parent.addReturnType(data) })
    
    paramState = State.new(:param, ->(parent, data){ parent.addParam(data) })
    
    paramTypeState = State.new(:param_type)
    
    paramDefaultExprState = State.new(:param_default_expr)
    
    paramDefaultExprCallState = State.new(:param_default_expr_call)
    
    paramDefaultValueState = State.new(:param_default_value, ->(parent, data){ parent.addParamDefault(data) })
    
    functionBodyState = State.new(:function_body)
    
    @@transitions = {
      # root of the file.
      :root => {
        :cursor_namespace => namespaceState,
      },
      # inside a namespace
      :namespace => {
        :cursor_namespace => namespaceState,
        :cursor_struct => structState,
        :cursor_class_decl => classState,
        :cursor_function => functionState,
        :cursor_class_template => classTemplateState,
        :cursor_enum_decl => enumState,
        :cursor_function_template => functionTemplateState,
      },
      # inside a class def
      :class => {
        :cursor_constructor => classConstructor,
        :cursor_destructor => classDestructor,
        :cursor_cxx_base_specifier => superClassState,
        :cursor_template_type_parameter => templateParamState,
        :cursor_struct => structState,
        :cursor_class_decl => classState,
        :cursor_union => unionState,
        :cursor_class_template => classTemplateState,
        :cursor_cxx_method => functionState,
        :cursor_function_template => functionTemplateState,
        :cursor_field_decl => fieldState,
        :cursor_enum_decl => enumState,
        :cursor_cxx_access_specifier => accessSpecifierState,
      },
      :base_class => {
        :cursor_type_ref => superClassTypeState,
        :cursor_template_ref => superClassTypeState,
      },
      :enum => {
        :cursor_enum_constant_decl => enumMemberState
      },
      # inside a function declaration
      :function => {
        :cursor_parm_decl => paramState,
        :cursor_type_ref => returnTypeState,
        :cursor_compound_stmt => functionBodyState,
      },
      :function_template => {
        :cursor_template_type_param => templateParamState,
        :cursor_type_ref => returnTypeState,
        :cursor_param_decl => paramState,
        :cursor_compound_stmt => functionBodyState,
      },
      # inside a function parameter declaration
      :param => {
        :cursor_template_ref => paramTypeState,
        :cursor_type_ref => paramTypeState,
        :cursor_unexposed_expr => paramDefaultExprState,
        :cursor_call_expr => paramDefaultExprCallState,
      },
      :param_default_expr_call => {
        :cursor_unexposed_expr => paramDefaultExprState,
        :cursor_call_expr => paramDefaultExprCallState,
        :cursor_template_ref => paramDefaultExprCallState,
        :cursor_type_ref => paramDefaultExprCallState,
      },
      :param_default_expr => {
        :cursor_floating_literal => paramDefaultValueState,
        :cursor_decl_ref_expr => paramDefaultValueState,
        :cursor_unexposed_expr => paramDefaultExprCallState,
      }
    }
  end
  
  def parse(visitor)
    cursor = @translator.cursor
    
    @depth = 0
    
    stateStack = [ :root ]
    data = [ StateData.new(visitor) ]
    visitChildren(cursor, visitor, stateStack, data)
    
    raise "Incomplete source" unless (stateStack.size == 1 && stateStack[0] == :root)
  end
  
private
  def visitChildren(cursor, visitor, states, data)
    parent = nil
    
    cursor.visit_children do |cursor, parent|
      puts ('  ' * @depth) + "#{cursor.kind} #{cursor.spelling.inspect} #{cursor.raw_comment_text}" unless not @debug

      oldType = states[-1]
      typeTransitions = @@transitions[oldType]
      source_error(cursor, "Unexpected child for #{oldType}, with child type #{cursor.kind}") unless typeTransitions

      transit = typeTransitions[cursor.kind]
      source_error(cursor, "Unexpected transition #{oldType} -> #{cursor.kind}") unless transit
      
      
      enterChildren = transit.enter(states, data, cursor)
      
      if(enterChildren)
        @depth = @depth + 1
        visitChildren(cursor, visitor, states, data)
        @depth = @depth - 1
      end
      
      transit.exit(states, data)
      
      next :continue
    end
    
  end

  def source_error(cursor, desc)
    loc = cursor.location
    raise "\n\nError, File: #{loc.file}, line: #{loc.line}, column: #{loc.column}: #{cursor.display_name}\n  #{desc}"
  end
  
end
