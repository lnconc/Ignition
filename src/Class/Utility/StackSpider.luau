--!native
--!nocheck
-- Class/Utility/StackSpider.lua

local Configuration = require("./Configuration")
local Types = require("../Types")


type Environment = Types.Environment

local MAX_DEPTH = Configuration.MAX_STACK_DEPTH
local IGNORED_LUA_CLOSURES = {
    ['pcall'] = true,
    ['xpcall'] = true,
    ['__index'] = true,
    ['__newindex'] = true,
}

local accessCache = setmetatable({}, { __mode = "k" })
local resolutionCache = setmetatable({}, { __mode = "k" })

local debugInfo = debug.info
local toString = tostring
local tableClone = table.clone

local function any_traversed_in_refs(traversed: { [string]: boolean }, refs: { [string]: boolean }): boolean
    for id in pairs(traversed) do
        if refs[id] then return true end
    end
    return false
end

local function upsertCache(key: string, tbl: any)
    local cache = accessCache[key]
    if cache then
        for k, v in next, tbl do
            cache[k] = v  
        end
    else
        accessCache[key] = tableClone(tbl)
    end
end

local function getMethodContext(level: number): (any?, string?)
    local f = debugInfo(level + 1, 'f')
    if not f then return nil, nil end
    return f, toString(f)
end

local function getEffectiveCaller(currentLevel: number): (any?, string?)
    local startLevel = currentLevel + 3
    local raw, rawName = getMethodContext(startLevel)
    if not raw then return nil, nil end
    
    local cached = resolutionCache[rawName]
    if cached then 
        return cached.m, cached.s 
    end

    local method, sign = raw, rawName
    for level = startLevel, startLevel + MAX_DEPTH do
        local currentMethod, currentName = getMethodContext(level)
        if not currentMethod then break end
        if not IGNORED_LUA_CLOSURES[currentName] then
            method, sign = currentMethod, currentName
            break
        end
    end

    resolutionCache[rawName] = { m = method, s = sign }
    return method, sign
end

local StackSpider = {}
function StackSpider.WithinScope(environment: Environment, _defaultLevel: number?): (boolean, boolean)
    local baseLevel = _defaultLevel or 3 
    
    local effectiveMethod, effectiveSign = getEffectiveCaller(baseLevel)
    if not effectiveMethod then return false, false end
    
    local cached = accessCache[effectiveSign]
    if cached then
        if not cached.included and any_traversed_in_refs(cached.traversed, environment.Context.Refs) then
            cached.included = true
        end
        return cached.included, cached.protected
    end

    local included, protected, traversed = false, false, {}
    local context = environment.Context
    local familyMap = context.Family[environment.Interface.name]

    for level = baseLevel, baseLevel + MAX_DEPTH do
        local method, name = getMethodContext(level)
        if not method then break end
        if not IGNORED_LUA_CLOSURES[name] then
            traversed[name] = true
            
            -- private
            if context.Includes[name] or context.Refs[name] or context.Friends[name] then
                included = true
                break
            end
            
            -- protected
            if familyMap and familyMap[name] then
                protected = true
                break
            end
        end
    end

    upsertCache(effectiveSign, { 
        included = included, 
        protected = protected, 
        traversed = traversed 
    })
    
    return included, protected
end

function StackSpider.WithinFunction(environment: Environment, targetFunction: string, _defaultLevel: number?): boolean
    local defaultLevel = _defaultLevel or 4
    local callerMethod, callerSign = getMethodContext(defaultLevel)
    if not callerMethod then return false end
    
    local cache = accessCache[callerSign]
    if cache and cache.within ~= nil then
        return cache.within
    end

    local includes = environment.Context.Includes
    local within = false
    
    for level = 0, MAX_DEPTH - 1 do
        local method, name = getMethodContext(defaultLevel + level)
        if not method then break end

        if includes[name] and name == targetFunction then
            within = true
            break
        end
    end

    upsertCache(callerSign, { within = within })
    return within
end

return StackSpider