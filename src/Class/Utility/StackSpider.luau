--!native
--!strict
-- Class/Utility/StackSpider.lua

local Configuration = require("./Configuration")

local MAX_DEPTH = Configuration.MAX_STACK_DEPTH
local IGNORED_LUA_CLOSURES = {
    ['pcall'] = true,
    ['xpcall'] = true,
    ['__index'] = true,
    ['__newindex'] = true,
}

local accessCache: setmetatable<{[typeof(function() end)]: {
    included: boolean,
    protected: boolean,
    traversed: { [typeof(function() end)]: boolean },
    within: boolean,
    [string]: any,
}}, { __mode: string }> = setmetatable({}, { __mode = "k" })
local resolutionCache: setmetatable<{[string?]: { m: any, s: string, [string]: any }}, { __mode: string }> = setmetatable({}, { __mode = "k" })

local debugInfo = debug.info
local toString = tostring
local tableClone = table.clone

local function any_traversed_in_refs(traversed: { [typeof(function() end)]: boolean }, refs: { [typeof(function() end)]: boolean }): boolean
    for id in pairs(traversed) do
        if refs[id] then return true end
    end
    return false
end

local function upsertCache(key: typeof(function() end), tbl: { [string]: any })
    local cache = accessCache[key]
    if cache then
        for k, v in next, tbl do
            cache[k] = v  
        end
    else
        accessCache[key] = tableClone(tbl)
    end
end

local function getMethodContext(level: number): (any, any, any)
    local f, n = debugInfo(level + 1, 'fn')
    return f, toString(f), n
end

local function getEffectiveCaller(currentLevel: number): (any)
    local startLevel = currentLevel + 2
    local raw = getMethodContext(startLevel)
    if not raw then return nil, nil end
    
    local cached = resolutionCache[raw]
    if cached then 
        return cached.m 
    end

    local method = raw
    for level = startLevel, startLevel + MAX_DEPTH do
        local currentMethod, _, name = getMethodContext(level)
        if not currentMethod then break end
        if not IGNORED_LUA_CLOSURES[name] then
            method = currentMethod
            break
        end
    end

    resolutionCache[raw] = { m = method }
    return method
end

local StackSpider = {}
function StackSpider.WithinScope<P>(environment: any, _defaultLevel: number?): (boolean, boolean)
    local baseLevel = _defaultLevel or 3
    
    local effectiveMethod = getEffectiveCaller(baseLevel)
    if not effectiveMethod then return false, false end
    local cached = accessCache[effectiveMethod]
    if cached then
        if not cached.included and cached.traversed and any_traversed_in_refs(cached.traversed, environment.Context.Refs) then
            cached.included = true
        end
        return cached.included, cached.protected
    end

    local included, protected, traversed = false, false, {}
    local context = environment.Context
    local familyMap = context.Family[environment.Interface.name]

    for level = baseLevel, baseLevel + MAX_DEPTH do
        local method, id, name = getMethodContext(level)
        if not method then break end
        if not IGNORED_LUA_CLOSURES[name] then
            traversed[method] = true
            
            -- private
            if context.Includes[id] or context.Refs[method] or context.Friends[id] then
                included = true
                break
            end
            
            -- protected
            if familyMap and familyMap[id] then
                protected = true
                break
            end
        end
    end

    upsertCache(effectiveMethod, { 
        included = included, 
        protected = protected, 
        traversed = traversed 
    })
    return included, protected
end

function StackSpider.WithinFunction<P>(environment: any, targetFunction: string, _defaultLevel: number?): boolean
    local baseLevel = _defaultLevel or 4
    local effectiveMethod = getEffectiveCaller(baseLevel)
    if not effectiveMethod then return false end
    
    local cached = accessCache[effectiveMethod]
    if cached then
        return cached.within
    end

    local includes = environment.Context.Includes
    local within = false
    
    for level = baseLevel, baseLevel + MAX_DEPTH do
        local method, name = getMethodContext(level)
        if not method then break end
        if includes[name] and name == targetFunction then
            within = true
            break
        end
    end

    upsertCache(effectiveMethod, { within = within })
    return within
end

function StackSpider.delete(closure: any)
    accessCache[closure] = nil
end

StackSpider.__accessCache = accessCache
StackSpider.__resolutionCache = resolutionCache

type StackSpider = {
    WithinFunction: <P>(environment: any, targetFunction: string, _defaultLevel: number?) -> boolean,
    WithinScope: <P>(environment: any, _defaultLevel: number?) -> (boolean, boolean)
}

return StackSpider :: StackSpider