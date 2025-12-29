--!strict
-- Class/LibraryTypes.luau
local Types = require("./Types")
type Interface = Types.Interface
type PropertiesFields = Types.PropertiesFields
type GetClassObject<I, A> = Types.GetClassObject<I, A>
type AnyFunction = Types.AnyFunction
type Symbol<T> = Types.Symbol<T>
type FinalProperty<T> = Types.FinalProperty<T>
type Property<T> = Types.Property<T>
type Nullable<T> = Types.Nullable<T>
type Union<T> = Types.Union<T>
type PropertyExposure = Types.PropertyExposure

export type ClassDSL = (name: string) -> (fields: PropertiesFields) -> boolean
export type ImportDSL = () -> setmetatable<{}, {
    __call: (self: any, targetOrSignature: AnyFunction | Types.Expects) -> (memberNameOrConstructor: string | AnyFunction) -> ((implementation: AnyFunction) -> ()) | nil,
    __newindex: (self: any, key: string, value: AnyFunction | any) -> (),
    __index: (self: any) -> any,
}>
export type NewDSL = <T>(className: T) -> (...any) -> GetClassObject<Interface, "Public">
export type ExtendsDSL = (superName: string) -> <T>(fields: T) -> T
export type MixinDSL = (name: string) -> (...string) -> (mixin_fields: PropertiesFields) -> ()

export type ClassLibrary = {
    -- core
    class: ClassDSL,
    import: ImportDSL,
    new: NewDSL,
    extends: ExtendsDSL,
    mixin: MixinDSL,
    from: (...string) -> (...any),

    -- modifiers
    abstract: (target: any) -> (),
    final: (target: any) -> (),
    reactive: (target: any) -> (),
    
    -- member definitions
    property: <P>(options: Property<P>) -> FinalProperty<P>?,
    func: (options: { exposure: PropertyExposure?, flags: { Symbol<string> }? } | any) -> FinalProperty<any>,
    
    -- type wrappers
    nullable: <T>(type: T) -> Nullable<T>,
    union: <T>(...T) -> Union<T>,
    
    -- runtime helpers
    free: (item: any) -> (),
    ref: <T>(callback: T) -> T,
    super: (...any) -> (),

    -- constants
    METADATA: Symbol<string>,
    PLACEHOLDER: Symbol<string>,
    FLAGS: {
        Optional: Symbol<string>,
        Static: Symbol<string>,
        Constant: Symbol<string>,
        Virtual: Symbol<string>,
        Readonly: Symbol<string>,
        Reactive: Symbol<string>,
    },

    [any]: any,
}

return {}