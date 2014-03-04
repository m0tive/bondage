require "ffi/clang.rb"

require_relative "Library.rb"
require_relative "Visitor.rb"
require_relative "Comment.rb"
require_relative "Type.rb"
require_relative "ParserData.rb"

class Parser
  def initialize(library, coreIncludes=[], dbg=false)
    @debug = false
    @index = FFI::Clang::Index.new
    @library = library

    sourceName = "DATA.cpp"

    args = [ "-fparse-all-comments", "-std=c++11", "/TC", sourceName ].concat(coreIncludes.map { |i| "-I#{i}" })

    library.includePaths.each do |path|
      args << "-I#{path}"
    end

    source = "#define BINDER_PARSING\n"
    library.files.each do |file|
      source << "#include \"#{file}\"\n"
    end

    unsaved = FFI::Clang::UnsavedFile.new(sourceName, source)

    @translator = @index.parse_translation_unit(nil, args, [ unsaved ], [ :detailed_preprocessing_record, :include_brief_comments_in_code_completion, :skip_function_bodies ])
  end

  def parse(visitor)
    cursor = @translator.cursor

    @depth = 0

    stateStack = [ :namespace ]
    data = [ visitor.rootItem ]
    visitChildren(cursor, visitor, stateStack, data)

    raise "Incomplete source" unless (stateStack.size == 1 && stateStack[0] == :namespace)
  end

  def displayDiagnostics
    diags = @translator.diagnostics
    diags.each do |diag|
      puts "#{diag.format}"
    end
  end

private
  def shouldIgnoreCursor(cursor)
    toFind = cursor.location.file
    if(@library.files.any?{ |path| toFind[-path.length, toFind.length] == path })
      return false
    end
    return true
  end

  def findNextState(oldType, cursor)
    typeTransitions = TRANSITIONS[oldType]
    source_error(cursor, "Unexpected child for #{oldType}, with child type #{cursor.kind}") unless typeTransitions

    newState = typeTransitions[cursor.kind]
    source_error(cursor, "Unexpected transition #{oldType} -> #{cursor.kind}") unless newState
    return newState
  end

  def visitChildren(cursor, visitor, states, data)
    cursor.visit_children do |cursor, parent|
      puts ('  ' * @depth) + "#{cursor.kind} #{cursor.spelling.inspect} #{cursor.raw_comment_text}" unless not @debug

      newState = findNextState(states[-1], cursor)

      if(@depth == 0 && shouldIgnoreCursor(cursor))
        next :continue          
      end

      enterChildren = newState.enter(states, data, cursor)

      if(enterChildren)
        @depth += 1
        visitChildren(cursor, visitor, states, data)
        @depth -= 1
      end

      newState.exit(states, data)

      next :continue
    end

  end

  def source_error(cursor, desc)
    loc = cursor.location
    raise "\n\nError, File: #{loc.file}, line: #{loc.line}, column: #{loc.column}: #{cursor.display_name}\n  #{desc}"
  end

end
