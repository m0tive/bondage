require_relative "ParserStateItem.rb"

NAMESPACE_STATE =               ParserStateItem.new(:namespace,               ->(parent, data){ parent.addNamespace(data) })
CLASS_STATE =                   ParserStateItem.new(:class,                   ->(parent, data){ parent.addClass(data) })
STRUCT_STATE =                  ParserStateItem.new(:class,                   ->(parent, data){ parent.addStruct(data) })
UNION_STATE =                   ParserStateItem.new(:class,                   ->(parent, data){ parent.addUnion(data) })
CLASS_CONSTRUCTOR_STATE =       ParserStateItem.new(:function,                ->(parent, data){ parent.addConstructor(data) })
CLASS_DESTRUCTOR_STATE =        ParserStateItem.new(:destructor)
SUPER_CLASS_STATE =             ParserStateItem.new(:base_class,              ->(parent, data) { parent.addSuperClass(data) })
SUPER_CLASS_TYPE_STATE =        ParserStateItem.new(:base_class_type)
CLASS_TEMPLATE_STATE =          ParserStateItem.new(:class,                   ->(parent, data){ parent.addClassTemplate(data) })
TEMPLATE_PARAM_STATE =          ParserStateItem.new(:param,                   ->(parent, data){ parent.addTemplateParam(data) })
ACCESS_SPECIFIER_STATE =        ParserStateItem.new(:access_specifier,        ->(parent, data){ parent.addAccessSpecifier(data) })
FIELD_STATE =                   ParserStateItem.new(:field,                   ->(parent, data){ parent.addField(data) })
ENUM_STATE =                    ParserStateItem.new(:enum,                    ->(parent, data){ parent.addEnum(data) })
ENUM_MEMBER_STATE =             ParserStateItem.new(:enumMember,              ->(parent, data){ parent.addEnumMember(data) })
ENUM_EXPR_STATE =               ParserStateItem.new(:enumExpr)
FUNCTION_STATE =                ParserStateItem.new(:function,                ->(parent, data){ parent.addFunction(data) })
FUNCTION_TEMPLATE_STATE =       ParserStateItem.new(:function_template,       ->(parent, data){ parent.addFunctionTemplate(data) })
RETURN_TYPE_NAMESPACE_STATE =   ParserStateItem.new(:return_type)
RETURN_TYPE_STATE =             ParserStateItem.new(:return_type)
PARAM_STATE =                   ParserStateItem.new(:param,                   ->(parent, data){ parent.addParam(data) })
PARAM_TYPE_STATE =              ParserStateItem.new(:param_type)
PARAM_DEFAULT_EXPR_STATE =      ParserStateItem.new(:param_default_expr,      ->(parent, data){ parent.addParamDefault(data) })
PARAM_DEFAULT_EXPR_CALL_STATE = ParserStateItem.new(:param_default_expr_call)
PARAM_DEFAULT_VALUE_STATE =     ParserStateItem.new(:param_default_value,     ->(parent, data){ parent.addParamDefault(data) })
FUNCTION_BODY_STATE =           ParserStateItem.new(:function_body)
FUNCTION_DECORATOR_STATE =      ParserStateItem.new(:function_body)
TYPEDEF_STATE =                 ParserStateItem.new(:typedef,                 ->(parent, data){ parent.addTypedef(data) })
UNEXPOSED_STATE =               ParserStateItem.new(:unexposed)

TRANSITIONS = {
  # inside a namespace
  :namespace => {
    :cursor_namespace => NAMESPACE_STATE,
    :cursor_struct => STRUCT_STATE,
    :cursor_class_decl => CLASS_STATE,
    :cursor_function => FUNCTION_STATE,
    :cursor_union => UNION_STATE,
    :cursor_typedef_decl => TYPEDEF_STATE,
    :cursor_class_template => CLASS_TEMPLATE_STATE,
    :cursor_enum_decl => ENUM_STATE,
    :cursor_unexposed_decl => UNEXPOSED_STATE,
    :cursor_function_template => FUNCTION_TEMPLATE_STATE,
  },
  # a typedef
  :typedef => {

  },
  # inside a class def
  :class => {
    :cursor_constructor => CLASS_CONSTRUCTOR_STATE,
    :cursor_destructor => CLASS_DESTRUCTOR_STATE,
    :cursor_cxx_base_specifier => SUPER_CLASS_STATE,
    :cursor_template_type_parameter => TEMPLATE_PARAM_STATE,
    :cursor_non_type_template_parameter => TEMPLATE_PARAM_STATE,
    :cursor_struct => STRUCT_STATE,
    :cursor_class_decl => CLASS_STATE,
    :cursor_union => UNION_STATE,
    :cursor_typedef_decl => TYPEDEF_STATE,
    :cursor_class_template => CLASS_TEMPLATE_STATE,
    :cursor_cxx_method => FUNCTION_STATE,
    :cursor_function_template => FUNCTION_TEMPLATE_STATE,
    :cursor_field_decl => FIELD_STATE,
    :cursor_enum_decl => ENUM_STATE,
    :cursor_cxx_access_specifier => ACCESS_SPECIFIER_STATE,
  },
  :base_class => {
    :cursor_type_ref => SUPER_CLASS_TYPE_STATE,
    :cursor_template_ref => SUPER_CLASS_TYPE_STATE,
    :cursor_namespace_ref => SUPER_CLASS_TYPE_STATE,
  },
  :enum => {
    :cursor_enum_constant_decl => ENUM_MEMBER_STATE,
  },
  :enumMember => {
    :cursor_unexposed_expr => ENUM_EXPR_STATE,
    :cursor_integer_literal => ENUM_EXPR_STATE,
  },
  # inside a function declaration
  :function => {
    :cursor_parm_decl => PARAM_STATE,
    :cursor_type_ref => RETURN_TYPE_STATE,
    :cursor_namespace_ref => RETURN_TYPE_NAMESPACE_STATE,
    :cursor_template_ref => RETURN_TYPE_STATE,
    :cursor_compound_stmt => FUNCTION_BODY_STATE,
    :cursor_cxx_override_attr => FUNCTION_DECORATOR_STATE
  },
  :function_template => {
    :cursor_template_type_param => TEMPLATE_PARAM_STATE,
    :cursor_non_type_template_parameter => TEMPLATE_PARAM_STATE,
    :cursor_namespace_ref => RETURN_TYPE_NAMESPACE_STATE,
    :cursor_type_ref => RETURN_TYPE_STATE,
    :cursor_template_ref => RETURN_TYPE_STATE,
    :cursor_param_decl => PARAM_STATE,
    :cursor_compound_stmt => FUNCTION_BODY_STATE,
    :cursor_cxx_override_attr => FUNCTION_DECORATOR_STATE
  },
  # inside a function parameter declaration
  :param => {
    :cursor_template_ref => PARAM_TYPE_STATE,
    :cursor_type_ref => PARAM_TYPE_STATE,
    :cursor_unexposed_expr => PARAM_DEFAULT_EXPR_STATE,
    :cursor_call_expr => PARAM_DEFAULT_EXPR_CALL_STATE,
    :cursor_floating_literal => PARAM_DEFAULT_VALUE_STATE,
    :cursor_cxx_bool_literal_expr => PARAM_DEFAULT_VALUE_STATE,
    :cursor_decl_ref_expr => PARAM_DEFAULT_VALUE_STATE,
  },
  :param_default_expr_call => {
    :cursor_unexposed_expr => PARAM_DEFAULT_EXPR_STATE,
    :cursor_call_expr => PARAM_DEFAULT_EXPR_CALL_STATE,
    :cursor_template_ref => PARAM_DEFAULT_EXPR_CALL_STATE,
    :cursor_type_ref => PARAM_DEFAULT_EXPR_CALL_STATE,
  },
  :param_default_expr => {
    :cursor_floating_literal => PARAM_DEFAULT_EXPR_CALL_STATE,
    :cursor_decl_ref_expr => PARAM_DEFAULT_VALUE_STATE,
    :cursor_unexposed_expr => PARAM_DEFAULT_EXPR_CALL_STATE,
    :cursor_cxx_null_ptr_literal_expr => PARAM_DEFAULT_EXPR_CALL_STATE,
  }
}