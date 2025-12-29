--!strict
-- Class/Types.lua

export type PropertyExposure = "shared" | "client" | "server"
export type Property<T> = {
    type: string,
    value: T,
    flags: { Symbol<string> } | { [Symbol<string>]: boolean },
    exposure: PropertyExposure,
}
export type FinalProperty<T> = setmetatable<Property<T>, { __metatable: string }>
export type CanBeProperty<T> = FinalProperty<T> | T

export type PropertyField = { [string]: CanBeProperty<any> }
export type PropertiesFields = {
    public: PropertyField,
    protected: PropertyField,
    private: PropertyField,
    [string]: CanBeProperty<any> | PropertyField,
}

export type Symbol<T> = setmetatable<{}, {
    __tostring: () -> string,
    __metatable: T,
    __call: () -> (),
}>

export type Nullable<T> = setmetatable<{ type: T }, { __metatable: string }>
export type Union<T> = setmetatable<{ types: { [T]: boolean } }, { __metatable: string }>

export type Expects = { string | Nullable<any> | Union<any> }
export type Function = <A..., R...>(A...) -> R... | () -> ()
export type ClassFunction = <A..., R...>(self: any, A...) -> R...
export type AnyFunction = ClassFunction | Function
export type OverloadEntry = { callback: AnyFunction, expects: Expects }
export type OverloadRecord = {
    isOverloaded: boolean,
    overloads: { OverloadEntry },
    fallback: AnyFunction
}
export type OverloadFunction = OverloadRecord | AnyFunction

export type Environment = {
    Context: {
        Includes: { [string]: boolean },
        Refs: setmetatable<{ [string]: boolean }, { __mode: string }>,
        Friends: { [string]: boolean },
        Family: { [string]: { [string]: boolean } },
        Constructor: string,
    },
    PropertyTypes: { [string]: string },
    PropertyFlags: { [string]: { [Symbol<string>]: boolean } },
    Id: Symbol<string>,
    Interface: Interface,
    Master: any?,
    SuperClass: {
        object: any?,
        environment: any?,
    },
}

export type Interface = setmetatable<{
    name: string,
    staticproperties: PropertiesFields,
    properties: PropertiesFields,
    flags: {
        AllowReactivity: boolean,
        ClassFinalized: boolean,
        ClassAbstracted: boolean,
        InheritanceLinked: boolean,
    },
    closures: { [string]: OverloadFunction? },
    constructor: {
        defined: boolean,
        callback: OverloadFunction?,
    },
    virtuals: { [string]: boolean },
    superclass: Interface?,
    instantiate: <A...>(self: Interface, fromDerivedClass: boolean, A...) -> (any, Environment),
}, { __metatable: string }>

export type function GetClassObject(interface: type, accessLevel: type): type
    local obj = types.newtable({})
    obj:setindexer(types.string, types.any)
    local level = accessLevel:value()
    local allowedScopes = { "public" }
    if level == "Protected" then table.insert(allowedScopes, "protected") end
    if level == "Private" then 
        table.insert(allowedScopes, "protected")
        table.insert(allowedScopes, "private") 
    end
    local function isStatic(memberWrapper: type): boolean
        local flags = memberWrapper:readproperty(types.singleton("flags"))
        if flags and flags:is("table") then
            for _, flagEntry in flags:properties() do
                local flag = flagEntry.read
                if not flag then continue end
                local mt = flag:metatable()
                if mt and mt:is("singleton") and mt:value() == "static" then
                    return true
                end
            end
        end
        return false
    end
    local propsRoot = interface:readproperty(types.singleton("properties"))
    if propsRoot then
        for _, scopeName in allowedScopes do
            local scope = propsRoot:readproperty(types.singleton(scopeName))
            if scope and scope:is("table") then
                for k, v in scope:properties() do
                    local wrapper = v.read
                    if wrapper and wrapper:is("table") then
                        obj:setproperty(types.singleton(k:value()), wrapper:readproperty(types.singleton("value")))
                    end
                end
            end
        end
    end
    local closures = interface:readproperty(types.singleton("closures"))
    if closures and closures:is("table") then
        for k, v in closures:properties() do
            local member = v.read
            if not member then continue end

            local functionSignatures = {}
            local static = isStatic(member)

            local function prepareSignature(func: type): type?
                if not func:is("function") then return nil end
                local copy = types.copy(func)
                if not static then
                    local params = copy:parameters()
                    local head = params.head or {}
                    table.insert(head, 1, obj) -- Inject instance type as 'self'
                    copy:setparameters(head, params.tail or types.any)
                end
                return copy
            end
            if member:is("function") then
                local sig = prepareSignature(member)
                if sig then table.insert(functionSignatures, sig) end
            elseif member:is("table") then
                local overloadsArr = member:readproperty(types.singleton("overloads"))
                if overloadsArr and overloadsArr:is("table") then
                    for _, entry in overloadsArr:properties() do
                        local entryVal = entry.read
                        if entryVal and entryVal:is("table") then
                            local cb = entryVal:readproperty(types.singleton("callback"))
                            if cb then
                                local sig = prepareSignature(cb)
                                if sig then table.insert(functionSignatures, sig) end
                            end
                        end
                    end
                end
                local fallback = member:readproperty(types.singleton("fallback"))
                if fallback then
                    local fallbackSig = prepareSignature(fallback)
                    if fallbackSig then table.insert(functionSignatures, fallbackSig) end
                end
            end

            if #functionSignatures > 0 then
                local finalType = functionSignatures[1]
                if #functionSignatures > 1 then
                    finalType = types.intersectionof(unpack(functionSignatures))
                end
                obj:setproperty(types.singleton(k:value()), finalType)
            end
        end
    end
    return obj
end

return {}