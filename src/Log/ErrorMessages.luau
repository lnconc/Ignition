--!strict
-- Log/Messages.luau
-- Ignition/Utility/ErrorMessages.luau

local ErrorMessages =  {
    -- Ignition Core
    ALREADY_LOADED = "Ignition has already loaded",
    THREAD_CONTEXT_REQUIRED = "%s must be called from a Luau thread context",
    CLASS_ENVIRONMENT_REQUIRED = "%s must be called inside a class function",
    CLASS_INTERFACE_REQUIRED = "%s must be called inside a class definition file",
    RAISE_DEV_MODE = "Class library is on Development Mode, set FORCE_PRODUCTION_MODE to true to disable",

    -- Reactive State
    CONSTANT_SET = "Cannot set constant from %s to %s",
    REACTIVE_EVAL_FAIL = "An error happened while attempting to evaluate state reactivity:\n%s",
    INST_WRAPPER_NO_DEST = "Creating a Value wrapping an Instance without a destructor may lead to memory leaks.",
    EXPOSE_CALLED_TWICE = "ExposeProperty can only be called once (Value metamethods initialization)",

    -- Registry & Definition
    CLASS_EXISTS = "Class '%s' already exists",
    OUT_OF_SCOPE = "Attempt to call Registry-related functions outside of Class scope (current caller: %s)",
    ILLEGAL_REGISTRY_CALL = "Attempt to illegally call Registry-related functions out of caller scope",
    WAIT_INTERFACE_TIMEOUT = "Infinite yield for WaitForInterface whilst waiting for Class '%s'",
    WRONG_FILE_EXT = "Class interface '%s' must be defined in a '.%s' file (got '%s')",
    WRITE_ONLY_IMPL = "'%s' implementation is write-only. Use the header for type info.",
    CANNOT_FIND_IMPLEMENTATION = "Cannot find implement %s as it is missing its definition",
    CONSTRUCTOR_EXISTS = "Constructor for %s already exists",
    INVALID_IMPORT_CALL = "Invalid import call. Expected a constructor or non-empty type signature.",
    CANNOT_FIND_FROM = "Unable to find %s from the Class library",
    CLASS_ABSTRACTED = "Cannot instantiate abstracted class %s",
    OBJECT_NOT_FOUND = "Attempt to access environment of a non-Ignition object or deleted instance",
    FINAL_TO_ABSTRACT = "Cannot abstract the finalized class %s",
    ABSTRACT_TO_FINAL = "Cannot finalize the abstract class %s",

    -- Inheritance & Mixins
    ALREADY_INHERITS = "'%s' already inherits from '%s'",
    INHERIT_FINALIZED = "Cannot inherit from finalized class '%s'",
    SELF_INHERITANCE = "Class '%s' cannot inherit from itself",
    MIXIN_FINALIZED = "Cannot mixin finalized class '%s' into '%s'",
    OVERRIDE_NON_VIRTUAL = "Cannot override non-virtual member '%s' in class '%s'",
    MISSING_SUPER = "Class '%s' has no superclass defined. Did you forget to use 'extends'?",
    MIXIN_COLLISION = "Member '%s' in '%s' is defined in multiple components (Check component: %s)",
    FALLBACK_EXISTS = "Fallback implementation for %s is already defined in %s.",

    -- Access Control (Visibility)
    PRIVATE_ACCESS = "Attempt to access private property '%s'",
    PROTECTED_ACCESS = "Attempt to access protected property '%s'",
    PRIVATE_WRITE = "Attempt to write private property '%s'",
    PROTECTED_WRITE = "Attempt to write protected property '%s'",
    READONLY_SET = "Cannot set readonly property '%s'",
    REQUIRED_SET_NIL = "Property '%s' cannot be optional",
    OPERATOR_VIOLATION = "Operator %s %s access violation",

    -- Runtime Dispatch
    MISSING_PROP_INDEX = "Attempt to index missing property '%s'",
    MISSING_PROP_WRITE = "Attempt to write missing property '%s'",
    MISSING_STATIC_INDEX = "%s is not a valid static member of %s",
    MISSING_STATIC_WRITE = "Cannot write static member %s of %s",
    NO_OVERLOAD_MATCH = "No overload for method '%s' matches the provided arguments:\n%s\ngot: %s",
    INVALID_CALL_SIG = "Invalid call signature: %s must be called with ':' on %s",
    UNIMPLEMENTED = "Method '%s' is unimplemented in %s",
    DESTROYED_OP = "Attempt to perform operation '%s' on a destroyed object",
    DELETING_STATE = "%s is currently being deleted!",
    FAILED_TYPE_CHECK = "Property %s expected a %s, got %s",
    DESTROYING_ERROR = "An error occured while destroying an object via delete()\n%s",
    THREAD_YIELDED = "Function %s had yielded",

    -- Friending
    FRIEND_TARGET_INVALID = "friend() subject must be a valid Class Object",
    FRIEND_GUEST_INVALID = "friend() guest must be a valid Class Object, function, or table; got %s",
    FRIEND_METHOD_NOT_FOUND = "Method '%s' not found in guest object",
}

export type ErrorMessages = typeof(ErrorMessages)

return ErrorMessages :: ErrorMessages