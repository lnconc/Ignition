--!strict
-- Class/Types.lua

local Generics = require("../Generics")
local Symbol = require("../Modules/Symbol")
local ValueTypes = require("../State/Types")

export type Symbol<T> = Symbol.Symbol<T>
type ValueFull<T> = ValueTypes.ValueFull<T>
type Effect<T> = ValueTypes.Effect<T>
type CanBe<T> = ValueTypes.CanBe<T>
export type Curry<T> = Generics.Curry<T>

export type Set<T> = Generics.Set<T>
export type Array<V> = Generics.Array<V>
export type Map<K, V> = Generics.Map<K, V>

export type Flags = Generics.Required<{
    AllowReactivity: boolean?,
    ClassAbstracted: boolean?,
    ClassFinalized: boolean?,
    InheritanceLinked: boolean?,
}>

export type Nullable<T> = typeof(setmetatable({} :: { type: T }, {} :: { __metatable: string }))
export type Union<T> = typeof(setmetatable({} :: { types: T }, {} :: { __metatable: string }))
export type SerializedFlags = { [Symbol.Symbol<string>]: boolean }

type NormalProperty<P> = {
    type: string | (value: P) -> boolean?,
    value: P?,
    flags: { Symbol<string> }?,
    exposure: string?
}
type ReactiveProperty<P> = { 
    effect: Effect<P>,
    dependencies: { [string]: any }?,
    exposure: string?
}
export type PropertyRaw<P> = NormalProperty<P> | ReactiveProperty<P>

export type Property<P> = typeof(setmetatable(
    {} :: PropertyRaw<P>, 
    {} :: { __metatable: string }
))

export type Function = <A..., R...>(A...) -> R...

type Field = Map<string, CanBe<any>>
export type FieldOptions = Map<any, Property<any> | any>

export type FieldsOption = Generics.Partial<{ 
    public: FieldOptions, 
    private: FieldOptions, 
    protected: FieldOptions 
}> & FieldOptions

export type Properties = {
    public: FieldOptions,
    private: FieldOptions,
    protected: FieldOptions,
    [string]: any,
}

export type SerializedProperties = { 
    public: Field, 
    private: Field,
    protected: Field,
    [string]: CanBe<any>, 
}

export type Options = {
    IdentifierName: string,
    StaticRoot: Interface,
    PropertyFields: Properties,
} & Flags

export type Expects = Array<string | Array<string>>
export type OverloadEntry = { callback: Function, expects: Expects }
export type OverloadRecord = { 
    fallback: Function?, 
    isOverloaded: boolean, 
    overloads: Array<OverloadEntry>
}

type InterfaceRaw = {
    name: string,
    instantiate: (self: Interface, fromDerivedClass: boolean, ...any) -> any,
    flags: Flags,
    constructor: { callback: (Function | OverloadRecord)?, defined: boolean },
    closures: { [string]: Function | OverloadRecord },
    globals: Map<unknown, CanBe<unknown>>,
    properties_fields: Properties,
    virtuals: Map<string, boolean>,
    superclass: any,
}
export type Interface =  typeof(setmetatable(
    {} :: InterfaceRaw, 
    {} :: { __metatable: string }
))

export type Environment = {
    Id: string,
    Interface: Interface,
    SuperClass: { object: any, environment: any },
    Context: {
        Includes: Set<string>,
        Refs: Set<string>,
        Friends: Set<string>,
        Family: Map<string, Set<string>>,
        Constructor: string?,
    },
    Closures: { any },
    Flags: {
        AllowReactivity: boolean,
    },
    Master: any,
    Self: any,
    PropertyFlags: Map<string, any>,
    PropertyTypes: Map<string, any>,
}

type OverloadSequence = (string) -> ((...any) -> (...any)) -> ()
type ReflectedClassCurry = (memberNameOrConstructor: any) -> (implementation: any) -> ()
export type ReflectedClass = typeof(setmetatable({}, {} :: {
    __newindex: (_self: any, key: any, value: any) -> (),
    __index: (_self: any) -> (),
    __call: (_self: any, targetOrSignature: any) -> ReflectedClassCurry?
}))

export type function TransformProperties(Props: type, level: "0" | "1" | "2")
    local result = types.newtable()
    
    local function merge_ring(ring_name: string)
        local ring = Props:readproperty(types.singleton(ring_name))
        if not ring or not ring:is("table") then return end
        
        for k, v in ring:properties() do
            local member_type = v.read :: type
            if member_type:is("table") and member_type:readproperty(types.singleton("value")) then
                local actual_val = member_type:readproperty(types.singleton("value"))
                result:setproperty(k, actual_val)
            else
                result:setproperty(k, member_type)
            end
        end
    end

    merge_ring("public")
    if level == "0" then
        merge_ring("protected")
        merge_ring("private")
    elseif level == "1" then
        merge_ring("protected")
    end

    return result
end

export type function Inherit(SubProps: type, SuperProps: type)
    local result = types.newtable()

    local superView = TransformProperties(SuperProps, "1")
    for k, v in superView:properties() do
        result:setproperty(k, v.read)
    end
    
    local subView = TransformProperties(SubProps, "0")
    for k, v in subView:properties() do
        result:setproperty(k, v.read)
    end

    return result
end

export type BaseObject<P> = TransformProperties<P, "2">
export type DerivedObject<P, S> = Inherit<P, S>
export type InternalObject<P> = TransformProperties<P, "0">

return {}