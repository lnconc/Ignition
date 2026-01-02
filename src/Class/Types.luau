--!strict
-- Class/Types.lua

export type PropertyExposure = "shared" | "client" | "server"

export type FinalProperty<V, T, D> = {
    type: T,
    value: V,
    dummy: D,
    flags: { Symbol<string> } | { [Symbol<string>]: boolean },
    _signature: string,
}

export type PropertyField = { [string]: FinalProperty<any, "any", any> | any }
export type PropertiesFields = {
    public: PropertyField,
    protected: PropertyField,
    private: PropertyField,
    [string]: FinalProperty<any, "any", any> | any | PropertyField,
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

export type function ForceSingleton(s: type): type
    if not s:is("singleton") then
        error("not a singleton")
    end
    return types.singleton(s:value())
end

export type function GetClassObject(interface: type, accessLevel: type): type
    local level = accessLevel:value()
    local allowedScopes = { "public" }
    if level == "Protected" then table.insert(allowedScopes, "protected") end
    if level == "Private" then
        table.insert(allowedScopes, "protected")
        table.insert(allowedScopes, "private")
    end
    local prototype = types.newtable({})
    prototype:setindexer(types.string, types.any)

    local PRIMITIVES = {
        any = types.any,
        unknown = types.unknown,
        boolean = types.boolean,
        number = types.number,
        string = types.string,
        thread = types.thread,
        buffer = types.buffer,
        ["nil"] = types.never,
        -- "table" is a special case we handle below
    }

    local funcs = types.newtable({}) -- store function types here to be modified later by ImportedClassObject
    local statics = types.newtable({})
    local props = types.newtable({})

    local function get_literal(t: type): string?
        if not t then return nil end
        if t:is("singleton") then
            local val = t:value()
            return if typeof(val) == "string" then val else nil
        end
        if t:is("union") then
            for _, comp in t:components() do
                if comp:is("singleton") then return comp:value() :: string? end
            end
        end
        if t:is("string") then return "string" end
        if t:is("number") then return "number" end
        if t:is("boolean") then return "boolean" end
        if t:is("unknown") then return "unknown" end
        if t:is("buffer") then return "buffer" end
        if t:is("thread") then return "thread" end
        if t:is("nil") then return "never" end
        return nil
    end

    local function is_static(member: type): boolean
        if not member:is("table") then return false end
        local flags = member:readproperty(types.singleton("flags"))
        if flags and flags:is("table") then
            for _, entry in flags:properties() do
                local flag = entry.read
                if flag and flag:is("table") then
                    local mt = flag:metatable()
                    if mt and mt:is("singleton") and mt:value() == "static" then return true end
                end
            end
        end
        return false
    end

    local function process_member(key: string, member: type)
        if not member or member:is("nil") then return end
        local asTable: type = nil :: any -- fix intersections causing us unable to read `type`, `value`, and `flags`
        if member:is("table") then asTable = member
        elseif member:is("union") then
            for _, component in member:components() do
                if component:is("table") then
                    asTable = component
                    break
                end
            end
        end
        if not asTable and member:metatable() then asTable = member end
        if asTable then
            local static = is_static(asTable)
            statics:setproperty(types.singleton(key), types.singleton(static))

            local sig = asTable:readproperty(types.singleton("_signature"))
            local propType = asTable:readproperty(types.singleton("type"))
            local innerValue = asTable:readproperty(types.singleton("value"))

            local typeLiteral = if propType then get_literal(propType) else nil
            local isLibrary = (sig ~= nil) or (typeLiteral ~= nil) or (innerValue ~= nil)
            if isLibrary then
                if typeLiteral == "function" then
                    local dummy = asTable:readproperty(types.singleton("dummy"))
                    local finalDummy: type? = nil

                    local function prepare_func(rawFunc: type): type
                        local params = rawFunc:parameters()
                        local returns = rawFunc:returns()
                        local head = if params.head then table.clone(params.head) else {}
                        
                        if not static then
                            if #head > 0 then head[1] = prototype else table.insert(head, 1, prototype) end
                        end
                        
                        return types.newfunction({
                            head = head,
                            tail = params.tail or types.any
                        }, returns)
                    end
                    if dummy then
                        if dummy:is("function") then
                            finalDummy = prepare_func(dummy)
                        elseif dummy:is("table") then
                            local combined: type? = nil
                            for _, entry in dummy:properties() do
                                local callback = entry.read
                                if not callback or not callback:is("function") then continue end
                                local transformed = prepare_func(callback)
                                combined = if combined then types.intersectionof(combined, transformed) else transformed
                            end
                            finalDummy = combined
                        end
                    end

                    if not finalDummy then
                        local params = { head = {}, tail = types.any }
                        if not static then table.insert(params.head, prototype) end
                        finalDummy = types.newfunction(params :: { head: {type}?, tail: type? }, { head = {}, tail = types.any })
                    end

                    funcs:setproperty(types.singleton(key), finalDummy)
                    prototype:setproperty(types.singleton(key), finalDummy)
                else
                    local resolvedType: type? = PRIMITIVES[typeLiteral] or nil
                    if typeLiteral == "table" then
                        local t = types.newtable({})
                        t:setindexer(types.any, types.any)
                        resolvedType = t
                    end
                    local finalType = resolvedType or innerValue or types.any
                    props:setproperty(types.singleton(key), finalType)
                    prototype:setproperty(types.singleton(key), finalType)
                end
            else
                props:setproperty(types.singleton(key), member)
                prototype:setproperty(types.singleton(key), member) -- raw primitive
            end
        end
    end

    local propsRoot = interface:readproperty(types.singleton("properties"))
    local closuresRoot = interface:readproperty(types.singleton("closures"))
    if propsRoot and closuresRoot then
        for _, scopeName in allowedScopes do
            local scope = propsRoot:readproperty(types.singleton(scopeName))
            if scope and scope:is("table") then
                for k, v in scope:properties() do
                    process_member(k:value() :: string, v.read :: type)
                end
            end
        end
        for k, v in closuresRoot:properties() do
            process_member(k:value() :: string, v.read :: type)
        end
    else
        for _, scopeName in allowedScopes do
            local scope = interface:readproperty(types.singleton(scopeName))
            if scope and scope:is("table") then
                for k, v in scope:properties() do
                    process_member(k:value() :: string, v.read :: type)
                end
            end
        end
        for k, v in interface:properties() do
            local keyName = k:value() :: string
            if keyName ~= "public" and keyName ~= "protected" and keyName ~= "private" then
                process_member(keyName, v.read :: type)
            end
        end
    end

    prototype:setreadproperty(types.singleton("__functions__"), funcs)
    prototype:setreadproperty(types.singleton("__statics__"), statics)
    prototype:setreadproperty(types.singleton("__props__"), props)
    prototype:setreadproperty(types.singleton("__interface__"), interface)
    return prototype
end

export type function ImportedClassObject(getClassObject: type): type
    local instance = types.newtable({}, { 
        index = types.string, 
        readresult = types.any, 
        writeresult = types.any 
    })
    
    local funcs = getClassObject:readproperty(types.singleton("__functions__"))
    local statics = getClassObject:readproperty(types.singleton("__statics__"))
    local props = getClassObject:readproperty(types.singleton("__props__"))

    if props then
        for k, v in props:properties() do
            instance:setproperty(k, v.read)
        end
    end

    if funcs and statics then
        for key, fn in funcs:properties() do
            local func = fn.read
            if not func then continue end
            local isStatic = false
            
            local staticFlag = statics:readproperty(key)
            if staticFlag and staticFlag:is("singleton") then
                isStatic = staticFlag:value() == true
            end

            if isStatic then
                instance:setproperty(key, func)
            else
                local params = func:parameters()
                local head = params.head or {}
                if #head > 0 then head[1] = instance else table.insert(head, 1, instance) end
                local reboundHeader = types.newfunction({
                    head = head,
                    tail = params.tail or types.any
                }, func:returns())
                instance:setproperty(key, reboundHeader)
            end
        end
    end
    local constructorFunc = types.newfunction({ head = { types.any }, tail = types.any }, { tail = types.any })
    local dslCall = types.newfunction({
        head = { types.any, constructorFunc }
    }, { head = { types.any } })
    local mt = types.newtable({
        [types.singleton("__call")] = dslCall,
    })
    instance:setmetatable(mt)
    return instance
end

export type function InheritFields(superInterface: type, subFields: type): type
    local mergedFields = types.newtable({})
    local scopes = { "public", "protected" }
    
    for _, scopeName in scopes do
        local scopeKey = types.singleton(scopeName)
        local newScope = types.newtable({})
        
        local superPropsRoot = superInterface:readproperty(types.singleton("properties"))
        if superPropsRoot then
            local superScope = superPropsRoot:readproperty(scopeKey)
            if superScope then
                for k, v in superScope:properties() do
                    newScope:setproperty(k, v.read)
                end
            end
        end
        
        local subScope = subFields:readproperty(scopeKey)
        if subScope then
            for k, v in subScope:properties() do
                newScope:setproperty(k, v.read)
            end
        end
        
        mergedFields:setproperty(scopeKey, newScope)
    end
    
   
    return mergedFields
end
export type function MergeInterfaces(interfaceList: type): type
    local result = types.newtable({})
    
    local propsRoot = types.newtable({})
    propsRoot:setproperty(types.singleton("public"), types.newtable({}))
    propsRoot:setproperty(types.singleton("protected"), types.newtable({}))
    propsRoot:setproperty(types.singleton("private"), types.newtable({}))
    result:setproperty(types.singleton("properties"), propsRoot)
    for _, entry in interfaceList:properties() do
        local comp = entry.read
        if not comp then continue end
        local compProps = comp:readproperty(types.singleton("properties"))
        if not compProps then continue end
        
        for _, scopeName in { "public", "protected", "private" } do
            local srcScope = compProps:readproperty(types.singleton(scopeName))
            local destScope = propsRoot:readproperty(types.singleton(scopeName))
            
            if srcScope and destScope then
                for k, v in srcScope:properties() do
                    destScope:setproperty(k, v.read)
                end
            end
        end
    end
    
    return result
end

return {}