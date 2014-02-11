# preamble helps us set up libclang, and ffi-clang. 
ENV['LLVM_CONFIG'] = "../llvm-build/Release+Asserts/bin/llvm-config"
ENV["PATH"] = ENV["PATH"] + ";" + Dir.getwd() + "/bin"

$:.unshift File.dirname(__FILE__) + "/../ffi-clang/lib"
require "ffi/clang.rb"

require_relative "library.rb"
require_relative "visitor.rb"

# ParamComment wraps a parameter comment, and its direction data
class ParamComment
  def initialize(text, expDir, dir)
    @text = text
    @explicitDirection = expDir
    @direction = dir
  end

  attr_reader :text, :explicitDirection, :direction
end

# Comment wraps a comment section in code, and any commands/param commands provided.
class Comment
  def initialize()
    @commands = {}
    @params = []
  end

  # add a simple command to the comment. [name] is the command, [text] the command text.
  def addCommand(name, text)
    @commands[name] = text
  end

  # add a param command to the comment. [index] is the parameter index, 
  # [text] is the brief for the param, [explicitDirection] is whether there was an 
  # explicit in or out direction, and dir is that direction
  def addParam(index, text, explicitDirection, dir)
    @params[index] = ParamComment.new(text, explicitDirection, dir)
  end

  # find if the comment has a command [name].
  def hasCommand(name)
    return @commands.has_key?(name)
  end

  # get the command text for the command [name].
  def command(name)
    return @commands[name]
  end

  # find a ParamCommand (or nil), for the param at [index].
  def paramforArgIndex(index)
    return @params[index]
  end
end

# Type wraps a parsed type from clang.
# Provided during argument/return type parsing.
class Type
  # create a type from the clang type.
  # it is not possible to create a type without a clang type.
  def initialize(type)
    @type = type
    @canonical = type.canonical
  end

  # strip any template brackets from the string [n].
  def self.stripTemplates(n)
    templateBrackets = 0
    endPoint = n.length
    (n.length-1).step(0, -1).each do |idx|
      isBracket = false
      if(n[idx] == ">")
        isBracket = true
        templateBrackets = templateBrackets + 1
      end

      if(n[idx] == "<")
        isBracket = true
        templateBrackets = templateBrackets - 1
      end

      if(templateBrackets == 0 && !isBracket)
        endPoint = idx + 1
        break
      end
    end

    return n[0, endPoint]
  end

  # find if the type is "void"
  def isVoid
    return @canonical.kind == :type_void
  end

  # find if the type is a bool
  def isBoolean
    return @canonical.kind == :type_bool
  end

  # find if the type is a const char* or a const wchar_t*
  def isStringLiteral
    if(!isPointer())
      return false
    end

    ptd = pointeeType()
    if(!ptd.isConstQualified())
      return false
    end

    return ptd.kind == :type_schar || ptd.kind == :type_wchar
  end

  # find if the type is an integer.
  def isInteger
    return @canonical.kind == :type_char_u ||
        @canonical.kind == :type_uchar ||
        @canonical.kind == :type_char16 ||
        @canonical.kind == :type_char32 ||
        @canonical.kind == :type_ushort ||
        @canonical.kind == :type_uint ||
        @canonical.kind == :type_ulong ||
        @canonical.kind == :type_ulonglong ||
        @canonical.kind == :type_uint128 ||
        @canonical.kind == :type_char_s ||
        @canonical.kind == :type_schar ||
        @canonical.kind == :type_wchar ||
        @canonical.kind == :type_short ||
        @canonical.kind == :type_int ||
        @canonical.kind == :type_long ||
        @canonical.kind == :type_longlong ||
        @canonical.kind == :type_int128
  end

  # find if the type is a floating point type.
  def isFloatingPoint
    return @canonical.kind == :type_float || @canonical.kind == :type_double || @canonical.kind == :type_longdouble
  end

  # find a pretty string to represent the type
  def prettyName
    return "#{@type.spelling}"
  end

  # find if the type has a const qualification
  def isConstQualified
    return @canonical.const_qualified?
  end

  # find a short name, without decoration or templating for the type.
  def name
    n = @canonical.spelling
    if(isConstQualified)
      n.sub!("const ", "")
    end

    return Type.stripTemplates(n)
  end

  # find the clang :kind for the type.
  def kind
    return @canonical.kind
  end

  # find if the type is a pointer
  def isPointer
    return @canonical.kind == :type_pointer
  end

  # find if the type is an lvalue reference
  def isLValueReference
    return @canonical.kind == :type_lvalue_ref
  end

  # find if the type is an rvalue reference
  def isRValueReference
    return @canonical.kind == :type_rvalue_ref
  end

  # find the type the pointer or reference refers to.
  def pointeeType
    return Type.new(@canonical.pointee)
  end

  # find a string description for the type, for debugging
  def description
    return "#{@canonical.spelling} #{@canonical.kind}"
  end

  # find the result type for this type, if the type is a function signature.
  def resultType
    if(@type.result_type.kind == :type_void)
      return nil
    end

    return Type.new(@type.result_type)
  end
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
    if (@onEnter && data[-1])
      newData = @onEnter.call(data[-1], newInfo)
    end
    
    data << newData
    
    return newData != nil
  end
  
  def exit(states, data)
    states.pop()
    data.pop()
  end
  
private
  def buildData(cursor)
    comment = Comment.new
    if(cursor.comment_range.start.file != nil)
      extractComment(comment, cursor.comment)
    end
    
    type = nil
    if(cursor.type.kind != :type_invalid)
      type = Type.new(cursor.type)
    end


    return {
      :name => cursor.spelling,
      :cursor => cursor,
      :type => type,
      :comment => comment,
      :accessSpecifier => cursor.access_specifier
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
        if(comment.valid_index?)
          toFill.addParam(comment.index, comment.comment, comment.direction_explicit?, comment.direction)
        end
      end
      
      comment.each do |comment|
        extractComment(toFill, comment)
      end
    end

    return comment
  end
end

class Parser
  def initialize(library, dbg)
    @debug = dbg
    @index = FFI::Clang::Index.new
    @library = library
    
    sourceName = "DATA.cpp"
    
    args = [ "-fparse-all-comments", "/TC", sourceName ]
    
    library.includePaths.each do |path|
      args << "-I#{path}"
    end
    
    source = "#define BINDER_PARSING\n"
    library.files.each do |file|
      source << "#include \"#{file}\"\n"
    end
    
    unsaved = FFI::Clang::UnsavedFile.new(sourceName, source)
    
    @translator = @index.parse_translation_unit(nil, args, [ unsaved ], [ :detailed_preprocessing_record, :include_brief_comments_in_code_completion, :skip_function_bodies ])
    
    namespaceState = State.new(:namespace, ->(parent, data){ parent.addNamespace(data) })
      
    classState = State.new(:class, ->(parent, data){ parent.addClass(data) })
    structState = State.new(:class, ->(parent, data){ parent.addStruct(data) })
    unionState = State.new(:class, ->(parent, data){ parent.addUnion(data) })

    classConstructor = State.new(:function, ->(parent, data){ parent.addConstructor(data) })
    classDestructor = State.new(:destructor)
    
    superClassState = State.new(:base_class, ->(parent, data) { parent.addSuperClass(data) })
    
    superClassTypeState = State.new(:base_class_type)
    
    classTemplateState = State.new(:class, ->(parent, data){ parent.addClassTemplate(data) })

    templateParamState = State.new(:param, ->(parent, data){ parent.addTemplateParam(data) })
    
    accessSpecifierState = State.new(:access_specifier, ->(parent, data){ parent.addAccessSpecifier(data) })
    
    fieldState = State.new(:field, ->(parent, data){ parent.addField(data) })
    
    enumState = State.new(:enum, ->(parent, data){ parent.addEnum(data) })
    
    enumMemberState = State.new(:enumMember, ->(parent, data){ parent.addEnumMember(data) })

    functionState = State.new(:function, ->(parent, data){ parent.addFunction(data) })

    functionTemplateState = State.new(:function_template, ->(parent, data){ parent.addFunctionTemplate(data) })
    
    returnTypeNamespaceState = State.new(:return_type)
    returnTypeState = State.new(:return_type)
    
    paramState = State.new(:param, ->(parent, data){ parent.addParam(data) })
    
    paramTypeState = State.new(:param_type)
    
    paramDefaultExprState = State.new(:param_default_expr)
    
    paramDefaultExprCallState = State.new(:param_default_expr_call)
    
    paramDefaultValueState = State.new(:param_default_value, ->(parent, data){ parent.addParamDefault(data) })
    
    functionBodyState = State.new(:function_body)
    
    @@transitions = {
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
        :cursor_non_type_template_parameter => templateParamState,
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
        :cursor_namespace_ref => superClassTypeState,
      },
      :enum => {
        :cursor_enum_constant_decl => enumMemberState
      },
      # inside a function declaration
      :function => {
        :cursor_parm_decl => paramState,
        :cursor_type_ref => returnTypeState,
        :cursor_namespace_ref => returnTypeNamespaceState,
        :cursor_template_ref => returnTypeState,
        :cursor_compound_stmt => functionBodyState,
      },
      :function_template => {
        :cursor_template_type_param => templateParamState,
        :cursor_non_type_template_parameter => templateParamState,
        :cursor_namespace_ref => returnTypeNamespaceState,
        :cursor_type_ref => returnTypeState,
        :cursor_template_ref => returnTypeState,
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
    
    stateStack = [ :namespace ]
    data = [ visitor.rootItem ]
    visitChildren(cursor, visitor, stateStack, data)
    
    raise "Incomplete source" unless (stateStack.size == 1 && stateStack[0] == :namespace)
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
      
      if(@depth == 0)
        toFind = cursor.location.file
        unless(@library.files.any?{ |path| toFind[-path.length, toFind.length] == path })
          next :continue
        end
      end

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
