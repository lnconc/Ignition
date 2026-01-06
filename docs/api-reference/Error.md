---
title: "Error Lexicon"
---

# :material-alert-octagon: Error Lexicon

This reference contains every error and warning code emitted by the Ignition engine. Use the keys below to identify and resolve issues in your class definitions and runtime logic.

---

## Ignition Core & Environment

### ALREADY_LOADED
!!! quote "`Ignition has already loaded`"
    Triggered if the library is initialized more than once in the same VM.

### THREAD_CONTEXT_REQUIRED
!!! quote "`%s must be called from a Luau thread context`"
    Thrown when a function requiring a coroutine or thread (for yielding safety) is called from a non-yielding context.

### CLASS_ENVIRONMENT_REQUIRED
!!! quote "`%s must be called inside a class function`"
    Thrown when attempting to call environment-specific logic (like `super()`) outside of a class method.

### CLASS_INTERFACE_REQUIRED
!!! quote "`%s must be called inside a class definition file`"
    Thrown when using class descriptors like `property` or `func` in a standard script instead of a `.class` definition file.

### RAISE_DEV_MODE
!!! quote "`Class library is on Development Mode, set FORCE_PRODUCTION_MODE to true to disable`"
    A reminder that production optimizations are currently disabled, ensuring standard safety checks and StackSpider monitoring are active.

---

## Reactive State

### CONSTANT_SET
!!! quote "`Cannot set constant from %s to %s`"
    An attempt was made to modify a `Value` atom that was locked as a constant during the class linking phase.

### REACTIVE_EVAL_FAIL
!!! quote "`An error happened while attempting to evaluate state reactivity: %s`"
    The internal `xpcall` caught an error within a `Property` or `Observe` effect. The specific Lua error is appended to the message.

### INST_WRAPPER_NO_DEST
!!! quote "`Creating a Value wrapping an Instance without a destructor may lead to memory leaks.`"
    **Warning:** A Roblox Instance has been wrapped in a `Value` atom without a provided cleanup method, risking "zombie" instances if the state is destroyed.

### EXPOSE_CALLED_TWICE
!!! quote "`ExposeProperty can only be called once (Value metamethods initialization)`"
    Internal engine error: The reactivity-to-class-bridge was initialized more than once.

---

## Registry & Definition

### CLASS_EXISTS
!!! quote "`Class '%s' already exists`"
    An attempt was made to define a class with a name that is already registered in the Ignition `Registry`.

### OUT_OF_SCOPE
!!! quote "`Attempt to call Registry-related functions outside of Class scope (current caller: %s)`"
    Registry logic was triggered from a script or context that is not recognized as a valid Ignition class scope.

### ILLEGAL_REGISTRY_CALL
!!! quote "`Attempt to illegally call Registry-related functions out of caller scope`"
    A security violation where a caller tried to bypass standard `Registry` access checks.

### WAIT_INTERFACE_TIMEOUT
!!! quote "`Infinite yield for WaitForInterface whilst waiting for Class '%s'`"
    The `WaitForInterface` utility exceeded its internal timeout while waiting for a specific class to be registered.

### WRONG_FILE_EXT
!!! quote "`Class interface '%s' must be defined in a '.%s' file (got '%s')`"
    Validation failed because the class definition file does not match the engine's required file extension.

### WRITE_ONLY_IMPL
!!! quote "`'%s' implementation is write-only. Use the header for type info.`"
    You attempted to read data from an implementation file; Ignition enforces that type info and headers are the primary source of truth.

### CANNOT_FIND_IMPLEMENTATION
!!! quote "`Cannot find implement %s as it is missing its definition`"
    The class header points to a definition file that cannot be located by the file loader.

### CONSTRUCTOR_EXISTS
!!! quote "`Constructor for %s already exists`"
    Multiple `constructor` calls were found within a single class definition.

### INVALID_IMPORT_CALL
!!! quote "`Invalid import call. Expected a constructor or non-empty type signature.`"
    An `import()` call was made with missing or malformed arguments.

### CANNOT_FIND_FROM
!!! quote "``Unable to find %s from the Class library`"
    A `from()` call failed to locate the requested` member or library component.

### CLASS_ABSTRACTED
!!! quote "`Cannot instantiate abstracted class %s"`
    An attempt was made to call `new()` on a class marked with the `abstract` modifier.

### OBJECT_NOT_FOUND
!!! quote "`Attempt to access environment of a non-Ignition object or deleted instance`"
    Triggered when trying to fetch the internal `Environment` of an object that is either not an Ignition instance or has already been garbage collected.

### FINAL_TO_ABSTRACT
!!! quote "`Cannot abstract the finalized class %s`"
    Definition Conflict: A class cannot be marked as `abstract` after it has already been finalized.

### ABSTRACT_TO_FINAL
!!! quote "`Cannot finalize the abstract class %s`"
    Definition Conflict: An `abstract` class cannot be finalized, as it must remain open for inheritance.

---

## Inheritance & Mixins

### ALREADY_INHERITS
!!! quote "`'%s' already inherits from '%s'`"
    Redundant `extends` call detected for a relationship that is already established.

### INHERIT_FINALIZED
!!! quote "`Cannot inherit from finalized class '%s'`"
    Inheritance violation: You cannot extend a class marked with the `final` modifier.

### SELF_INHERITANCE
!!! quote "`Class '%s' cannot inherit from itself`"
    Logic error where a class attempted to use its own name in an `extends` call.

### MIXIN_FINALIZED
!!! quote "`Cannot mixin finalized class '%s' into '%s'`"
    An attempt was made to use a `final` class as a component for a `mixin`.

### OVERRIDE_NON_VIRTUAL
!!! quote "`Cannot override non-virtual member '%s' in class '%s'`"
    A child class tried to overwrite a member that was not explicitly marked with the `Virtual` flag in the superclass.

### MISSING_SUPER
!!! quote "`Class '%s' has no superclass defined. Did you forget to use 'extends'?`"
    A `super()` call was found in a constructor or method, but no parent class exists in the inheritance chain.

### MIXIN_COLLISION
!!! quote "`Member '%s' in '%s' is defined in multiple components (Check component: %s)`"
    Two or more mixins are providing a member with the same name, resulting in a naming collision.

### FALLBACK_EXISTS
!!! quote "`Fallback implementation for %s is already defined in %s.`"
    Multiple fallback implementations were provided for the same overloaded method.

---

## Access Control (Visibility)

### PRIVATE_ACCESS
!!! quote "`Attempt to access private property '%s'`"
    Unauthorized read: The `StackSpider` blocked an external caller from reading a `private` member.

### PROTECTED_ACCESS
!!! quote "`Attempt to access protected property '%s'`"
    Unauthorized read: The caller is neither a subclass nor a friend of the target object.

### PRIVATE_WRITE
!!! quote "`Attempt to write private property '%s' %s`"
    Unauthorized write: An external caller attempted to modify a `private` member.

### PROTECTED_WRITE
!!! quote "`Attempt to write protected property '%s' %s`"
    Unauthorized write: An external caller attempted to modify a `protected` member.

### READONLY_SET
!!! quote "`Cannot set readonly property '%s'`"
    Access violation: Attempted to modify a property marked with the `Readonly` flag after the initialization phase.

### REQUIRED_SET_NIL
!!! quote "`Property '%s' cannot be optional`"
    Integrity violation: A property not marked with the `Optional` flag was set to `nil`.

### OPERATOR_VIOLATION
!!! quote "`Operator %s %s access violation`"
    The `StackSpider` blocked a metatable operator (e.g., `__add`) because the caller lacked sufficient visibility.

---

## Runtime Dispatch

### MISSING_PROP_INDEX
!!! quote "`Attempt to index missing property '%s'`"
    The requested property does not exist in any visibility ring of the object.

### MISSING_PROP_WRITE
!!! quote "`Attempt to write missing property '%s'`"
    Ignition objects are sealed at runtime. You cannot add new properties to an instance after it has been created.

### MISSING_STATIC_INDEX
!!! quote "`%s is not a valid static member of %s`"
    The requested key was not found in the Class Interface's static property ring.

### MISSING_STATIC_WRITE
!!! quote "`Cannot write static member %s of %s`"
    Static members are immutable once the class definition is finalized.

### NO_OVERLOAD_MATCH
!!! quote "`No overload for method '%s' matches the provided arguments: %s got: %s`"
    Dispatch failure: The arguments provided do not match any of the defined function signatures for this overloaded method.

### INVALID_CALL_SIG
!!! quote "`Invalid call signature: %s must be called with ':' on %s`"
    The method was called using the `.` operator, causing the `self` argument to be missing.

### UNIMPLEMENTED
!!! quote "`Method '%s' is unimplemented in %s`"
    An abstract or virtual method was called but no implementation was found in the inheritance chain.

### DESTROYED_OP
!!! quote "`Attempt to perform operation '%s' on a destroyed object`"
    The object has already been cleaned up via `delete()` and its environment has been purged.

### DELETING_STATE
!!! quote "`%s is currently being deleted!`"
    An operation was attempted while the object was in the middle of its destruction lifecycle.

### FAILED_TYPE_CHECK
!!! quote "`Property %s expected a %s, got %s`"
    Type violation: The assigned value failed either the primitive `typeof` check or the `CustomType.match` validation.

### DESTROYING_ERROR
!!! quote "`An error occured while destroying an object via delete() %s`"
    The object's destructor threw an error. The stack trace is provided for debugging.

### THREAD_YIELDED
!!! quote "`Function %s had yielded`"
    The named function had yielded in an unyieldable context.

---

## Friending

### FRIEND_TARGET_INVALID
!!! quote "`friend() subject must be a valid Class Object`"
    The "subject" granting access must be a registered Ignition instance.

### FRIEND_GUEST_INVALID
!!! quote "`friend() guest must be a valid Class Object, function, or table; got %s`"
    The "guest" receiving access must be an entity that Ignition can track (Object, closure, or library table).

### FRIEND_METHOD_NOT_FOUND
!!! quote "`Method '%s' not found in guest object`"
    When performing specific method friending, the provided name could not be resolved in the guest's visibility rings.