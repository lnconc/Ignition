--!strict
-- Class/Types.lua

type Exposure = "shared" | "client" | "server"

type Symbol<T> = setmetatable<{}, {
    __tostring: () -> string,
    __metatable: T,
    __call: () -> (),
}>

type function CopyProps(src: type?, dest: type?)
    if src and dest then
        for k, v in src:properties() do dest:setproperty(k, v.read) end
    end
end

type function CreateLazyPrototype(): type
    local prototype = types.newtable({})
    prototype:setindexer(types.string, types.any)
    prototype:setreadproperty(types.singleton("__lazy__"), types.singleton(true))
    return prototype
end

type function IsInterfaceLazy(interface: type): boolean
    local lazySet = {
        ["string"] = true,
        ["any"] = true,
        ["singleton"] = true,
        ["unknown"] = true,
        ["nil"] = true,
        ["never"] = true,
    }
    return lazySet[interface.tag] ~= nil
end

type function GetScopes(access_level: type): {string}
    local level = access_level:value()
    local scopes = { "public" }
    if level == "Protected" or level == "Private" then table.insert(scopes, "protected") end
    if level == "Private" then table.insert(scopes, "private") end
    return scopes
end

type function InferPropertyType(options: type): type
    local emptySet = {
        ["unknown"] = true,
        ["nil"] = true,
        ["never"] = true,
    }
    local typeField = options:readproperty(types.singleton("type"))
    if typeField and not emptySet[typeField.tag] then
        return typeField
    end
    local valueField = options:readproperty(types.singleton("value"))
    if not valueField or emptySet[valueField.tag] ~= nil then
        return types.any
    end
    return valueField
end

export type function GetClassObject(interface: type, access_level: type): type
    if IsInterfaceLazy(interface) then return CreateLazyPrototype() end
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
    local allowedScopes = GetScopes(access_level)
    local prototype = types.newtable({})
    prototype:setindexer(types.string, types.any)
    local funcs, statics, props = types.newtable({}), types.newtable({}), types.newtable({})
    
    local function check(t: type, f: string)
        local mt = if t:is("table") then t:metatable() else nil
        local __mt = mt and mt:readproperty(types.singleton("__metatable"))
        return __mt and __mt:value() == f
    end

    local function has_flag(member: type, flag: string): boolean
        local flags = member:readproperty(types.singleton("flags"))
        if flags and flags:is("table") then
            local indexer = flags:indexer()
            if indexer then
                local indexValue = indexer.readresult
                if indexValue:is("union") then
                    for _, component in indexValue:components() do
                        if check(component, flag) then return true end
                    end
                elseif check(indexValue, flag) then
                    return true
                end
            end
        end
        return false
    end

    local function prepare_func(func: type, static: boolean): type
        local params = func:parameters()
        local returns = func:returns()
        local head = if params.head then table.clone(params.head) else {}
        
        if not static then
            if #head > 0 then head[1] = prototype else table.insert(head, 1, prototype) end
        end
        
        return types.newfunction({
            head = head,
            tail = params.tail or types.any
        }, returns)
    end
    
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
        if t:is("nil") then return "nil" end
        return nil
    end
    
    local function normalize(member: type): type
        if member:is("intersection") then
            local components = member:components()
            for i = #components, 1, -1 do
                local comp = components[i]
                if comp:is("table") then
                    return normalize(comp)
                end
            end
        end

        if member:is("table") then
            local is_prop = member:metatable() == types.singleton("$property")
            if is_prop then
                local type = member:readproperty(types.singleton("type"))
                local value = member:readproperty(types.singleton("value"))
                if not type or not value then return member end
                local literal = get_literal(type)
                if literal and PRIMITIVES[literal] then
                    return PRIMITIVES[literal]
                end
                
                return if not value:is("nil") then value else types.any
            end
        end
        return member
    end

    local function append(key: type, member: type)
        props:setproperty(key, normalize(member))
        prototype:setproperty(key, normalize(member))
    end

    local function process(key: type, member: type)
        if member:is("union") then
            local components = member:components()
            for i = #components, 1, -1 do
                local comp = components[i]
                if comp:is("table") then
                    member = comp
                    break
                end
            end
        end
        if member:is("table") then
            local mt = member:metatable()
            local is_prop = false
            if mt then
                local __mt = mt:readproperty(types.singleton("__metatable"))
                is_prop = __mt and __mt:value() == "$property"
            end
            if not is_prop then
                append(key, member)
                return
            end
            local is_static, is_reactive = has_flag(member, "static"), has_flag(member, "reactive")
            statics:setreadproperty(key, types.singleton(is_static))

            local type = member:readproperty(types.singleton("type")) :: type -- this always exist
            local value = member:readproperty(types.singleton("value"))
            
            local literal = get_literal(type)
            if literal == "function" then
                local dummy = member:readproperty(types.singleton("dummy"))
                local finalDummy: type? = nil
                if dummy then
                    if dummy:is("function") then
                        finalDummy = prepare_func(dummy, is_static)
                    elseif dummy:is("table") then
                        local combined: type? = nil
                        local indexer = dummy:indexer()
                        if indexer then
                            local element = indexer.readresult
                            if element:is("union") then
                                for _, component in element:components() do
                                    if component:is("function") then
                                        local transformed = prepare_func(component, is_static)
                                        combined = if combined then types.intersectionof(combined, transformed) else transformed
                                    end
                                end
                            elseif element:is("function") then
                                combined = prepare_func(element, is_static)
                            end
                        end
                        finalDummy = combined
                    end
                end

                if not finalDummy then
                    local params = { head = {}  }
                    if not is_static then table.insert(params.head, prototype) end
                    finalDummy = types.newfunction(params :: { head: {type}?, tail: type? }, {})
                end

                funcs:setproperty(key, finalDummy)
                prototype:setproperty(key, finalDummy)
            elseif value then
                local resolvedType: type = if literal then PRIMITIVES[literal] else type
                local getter = member:readproperty(types.singleton("get"))
                if getter then
                    local funcType: type? = nil
                    if getter:is("function") then
                        funcType = getter
                    elseif getter:is("union") then
                        for _, comp in getter:components() do
                            if comp:is("function") then
                                funcType = comp
                                break
                            end
                        end
                    end
                    
                    if funcType then
                        local returns = funcType:returns()
                        if returns and returns.head and #returns.head > 0 then
                            resolvedType = returns.head[1]
                        end
                    end
                end
                if literal == "table" then
                    if value:is("table") then
                        resolvedType = value
                    else
                        local t = types.newtable({})
                        t:setindexer(types.any, types.any)
                        resolvedType = t
                    end
                end
                if is_reactive then
                    local valueType = types.newtable({})
                    valueType:setproperty(types.singleton("set"), types.newfunction({head = {types.any, resolvedType}}, {}))
                    resolvedType = valueType
                end
                append(key, resolvedType)
            else
                append(key, member)
            end
        else
            append(key, member)
        end
    end
    
    local propsRoot = interface:readproperty(types.singleton("properties"))
    local closuresRoot = interface:readproperty(types.singleton("closures"))

    for _, scopeName in allowedScopes do
        local scope = (propsRoot or interface):readproperty(types.singleton(scopeName))
        if scope and scope:is("table") then
            for k, v in scope:properties() do
                local value = v.read
                if not value then continue end
                process(k, value)
            end
        end
    end

    if closuresRoot then
        for k, v in closuresRoot:properties() do
            local value = v.read
            if not value then continue end
            process(k, value)
        end
    end

    prototype:setreadproperty(types.singleton("__functions__"), funcs)
    prototype:setreadproperty(types.singleton("__statics__"), statics)
    prototype:setreadproperty(types.singleton("__props__"), props)
    prototype:setreadproperty(types.singleton("__interface__"), interface :: any)
    return prototype
end

export type function StaticClassObject(getClassObject: type): type
    local staticInstance = types.newtable({}, { index = types.string, readresult = types.any, writeresult = types.any })
    local statics = getClassObject:readproperty(types.singleton("__statics__"))
    local function apply(source: type?)
        if not source then return end
        if not statics then return end
        for k, v in source:properties() do
            local static = statics:readproperty(k)
            if static and static:value() == true then
                staticInstance:setproperty(k, v.read)
            end
        end
    end

    apply(getClassObject:readproperty(types.singleton("__props__")))
    apply(getClassObject:readproperty(types.singleton("__functions__")))
    
    staticInstance:setproperty(types.singleton("__interface__"), getClassObject:readproperty(types.singleton("__interface__")))
    return staticInstance
end

export type function ComposeInterfaces(access_level: type, parents: type?, localFields: type?): type
    if not parents or IsInterfaceLazy(parents) then 
        return CreateLazyPrototype() 
    end
    
    local allowedScopes = GetScopes(access_level)

    local result = types.newtable({})
    local propsRoot = types.newtable({})

    for _, s in allowedScopes do 
        propsRoot:setproperty(types.singleton(s), types.newtable({})) 
    end
    result:setproperty(types.singleton("properties"), propsRoot)

    local function merge(source: type?)
        if not source then return end
        local data = source:readproperty(types.singleton("properties")) or source
        for _, s in allowedScopes do
            CopyProps(data:readproperty(types.singleton(s)), propsRoot:readproperty(types.singleton(s)))
        end
    end

    local indexer = parents:indexer()
    if indexer then
        local component = indexer.readresult
        if component:is("union") then
            for _, comp in component:components() do
                merge(comp)
            end
        else
            merge(component)
        end
    end

    merge(localFields)
    
    return result
end

export type function ImportedClassObject(getClassObject: type): type
    if getClassObject:readproperty(types.singleton("__lazy__")) then
        local lazy = CreateLazyPrototype()
        local dsl = types.newfunction({ head = { types.any, types.any } }, { head = { types.any } })
        lazy:setmetatable(types.newtable({ [types.singleton("__call")] = dsl }))
        return lazy
    end

    local instance = types.newtable({}, { index = types.string, readresult = types.any, writeresult = types.any })
    local funcs = getClassObject:readproperty(types.singleton("__functions__"))
    local statics = getClassObject:readproperty(types.singleton("__statics__"))
    local props = getClassObject:readproperty(types.singleton("__props__"))
    CopyProps(props, instance)

    if funcs and statics then
        for key, fn in funcs:properties() do
            local func = fn.read
            if not func then continue end
            local sFlag = statics:readproperty(key)
            local is_static = sFlag and sFlag:is("singleton") and sFlag:value() == true

            if is_static then
                instance:setproperty(key, func)
            else
                local p = func:parameters()
                local head = if p.head then table.clone(p.head) else {}
                if #head > 0 then head[1] = instance else table.insert(head, 1, instance) end
                instance:setproperty(key, types.newfunction({
                    head = head, 
                    tail = p.tail or types.any
                }, func:returns()))
            end
        end
    end
    
    local signatureTable = types.newtable({})
    signatureTable:setindexer(types.number, types.string)

    local constructorCallback = types.newfunction(
        { head = { instance }, tail = types.any }, 
        { tail = types.any }
    )
    local methodImplSetter = types.newfunction(
        { head = { types.newfunction({ head = { instance }, tail = types.any }, { tail = types.any }) } }, 
        { head = { types.never } }
    )
    
    local overloadResult = types.newfunction(
        { head = { types.unionof(types.string, constructorCallback) } }, 
        { head = { types.unionof(methodImplSetter, types.never) } }
    )
    local dslCall = types.newfunction({
        head = { 
            types.any, -- self
            types.unionof(types.singleton(true), constructorCallback, signatureTable) -- arg1
        }
    }, { 
        head = { 
            types.unionof(StaticClassObject(getClassObject), overloadResult, types.never) 
        } 
    })
    instance:setmetatable(types.newtable({
        [types.singleton("__call")] = dslCall,
    }))
    return instance
end

export type function UnwrapClassObject(input: type): type
    local interfaceKey = types.singleton("__interface__")
    if input:is("union") then
        for _, component in input:components() do
            if component:readproperty(interfaceKey) then
                input = component
                break
            end
        end
    end
    if IsInterfaceLazy(input) then return types.any end
    local raw = input:readproperty(interfaceKey)
    return GetClassObject(raw or input, types.singleton("Public"))
end

export type Class = {
    class: (name: string) -> <I>(fields: I) -> I,
    import: <I>(interface: I?) -> ImportedClassObject<GetClassObject<I, "Private">>,
    new: <I>(interface: I) -> (...any) -> UnwrapClassObject<I>,
    extends: <I>(superInterface: I) -> <J>(fields: J) -> ComposeInterfaces<"Private", {I}, J>,
    super: (...any) -> (),
    mixin: (name: string) -> <I>(...I) -> <J>(fields: J) -> ComposeInterfaces<"Private", {I}, J>,

    from: (...string) -> ...any,
    unwrap: <I>(staticInterface: I) -> UnwrapClassObject<I>,

    abstract: <I>(target: I) -> I,
    reactive: <I>(target: I) -> I,
    final: <I>(target: I) -> I,

    property: <V, T, H, A, Q, R, F>(options: {
        type: T?,
        value: V?,
        flags: {F}?,
        from: Exposure?,
        get: H?,
        set: ((value: A, this: Q) -> R)?,
        effect: (<T, U>(effect: <T0, U0...>(use: <T1>(value: T1) -> T1, U0...) -> T0, data: U) -> any)?,
        dependencies: { [any]: any }?,
        [string]: any,
    } & any) -> setmetatable<{
        type: InferPropertyType<{ type: T, value: V }>,
        value: V,
        flags: {F},
        from: Exposure,
        get: H?,
        set: ((value: A, this: Q) -> R)?,
        effect: (<T, U>(effect: <T0, U0...>(use: <T1>(value: T1) -> T1, U0...) -> T0, data: U) -> any)?,
        dependencies: { [any]: any }?,
    }, { read __metatable: "$property" }>?,
    func: <D, F>(options: {
        flags: {F}?,
        from: Exposure?,
        dummy: D?,
        [string]: any,
    }) -> setmetatable<{
        type: "function",
        flags: {F},
        dummy: D,
        from: Exposure,
    }, { read __metatable: "$property" }>?,

    nullable: <T>(type: T) -> setmetatable<{ type: T }, { read __metatable: "$nullable "}>,
    union: <T>(...T) -> setmetatable<{ types: { [T]: boolean } }, { read __metatable: "$union "}>,
    
    free: (item: any) -> (),
    delete: (object: any) -> (),
    ref: <T>(callback: T) -> T,
    anon: <T>(callback: T) -> T,
    
    friend: (subject: any, guest: any, methodName: string?) -> (),
    mutual: (objectA: any, objectB: any) -> (),
    
    dumpsize: () -> string,

    METADATA: Symbol<"metadata">,
    PLACEHOLDER: any,
    FLAGS: {
        Optional: Symbol<"optional">,
        Static: Symbol<"static">,
        Constant: Symbol<"constant">,
        Virtual: Symbol<"virtual">,
        Readonly: Symbol<"readonly">,
        Reactive: Symbol<"reactive">,
    },
}

return {}