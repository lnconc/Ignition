--!strict
-- Class/LibraryTypes.luau
local Types = require("./Types")
type Interface = Types.Interface
type PropertiesFields = Types.PropertiesFields
type GetClassObject<I, A> = Types.GetClassObject<I, A>
type AnyFunction = Types.AnyFunction
type Symbol<T> = Types.Symbol<T>
type FinalProperty<V, T, D> = Types.FinalProperty<V, T, D>
type Nullable<T> = Types.Nullable<T>
type Union<T> = Types.Union<T>
type PropertyExposure = Types.PropertyExposure
type ImportedClassObject<G> = Types.ImportedClassObject<G>
type InheritFields<S1, S2> = Types.InheritFields<S1, S2>
type MergeInterfaces<I> = Types.MergeInterfaces<I>

export type ClassDSL = (name: string) -> <I>(fields: PropertiesFields & I) -> I
export type ImportDSL = <I>(interface: I | string) -> ImportedClassObject<GetClassObject<I, "Private">>
export type NewDSL = <I>(interface: I | string) -> (...any) -> GetClassObject<I, "Public">
export type ExtendsDSL = <I>(superInterface: I | string) -> <J>(fields: PropertiesFields & J) -> InheritFields<I, J>
export type MixinDSL = (name: string) -> <I>(...I | string) -> (mixin_fields: PropertiesFields) -> MergeInterfaces<I>
export type ClassLibrary = {
    -- core
    class: ClassDSL,
    import: ImportDSL,
    new: NewDSL,
    extends: ExtendsDSL,
    mixin: MixinDSL,
    from: (...string) -> (...any),

    -- modifiers
    abstract: <I>(target: I) -> I,
    final: <I>(target: I) -> I,
    reactive: <I>(target: I) -> I,
    
    -- member definitions
    property: <V, T>(options: {
        type: T,
        value: V,
        flags: { Symbol<string> } | { [Symbol<string>]: boolean },
    }) -> FinalProperty<V, T, nil>?,
    func: <D>(options: { 
        exposure: PropertyExposure?, 
        flags: { Symbol<string> }?, 
        dummy: D 
    }) -> FinalProperty<nil, "function", D>,    
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
}

return {}