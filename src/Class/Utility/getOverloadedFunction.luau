--!strict
-- Class/Utility/getOverloadedFunction.lua

local Log = require("../../Log")
local Configuration = require("./Configuration")

local function matchSignature(arg: any, expected: any): boolean
    if expected == nil or expected == "any" then return true end
    local argType = typeof(arg)
    if type(expected) == "table" then
        local mt = getmetatable(expected)
        if mt == Configuration.NULLABLE_SIGNATURE and arg == nil then
            return true
        end
        if mt == Configuration.UNION_SIGNATURE then
            return expected.types[argType] ~= nil
        end
        return matchSignature(arg, expected.type)
    end
    return argType == expected
end

local function is_type_helper(x: any): boolean
    return type(x) == "table" and type(x._signature) == "string" and (x.type ~= nil or x.types ~= nil)
end

local function normalizeSignature(x: any): string
    local sig = { x.type }
    if x.types then
        for t in pairs(x.types :: { [any]: boolean }) do
            if is_type_helper(t) then
                t = normalizeSignature(t)
            end
            table.insert(sig, t)
        end
    end
    return `{x._signature:sub(2)}({table.concat(sig, ",")})`
end

local function getSignature(args: { any }, count: number): string
    local sig: {string} = {}
    for i = 1, count do
        local arg = args[i]
        local t: string = typeof(arg)
        if is_type_helper(arg) then
            t = normalizeSignature(arg)
        end
        table.insert(sig, t)
    end
    return table.concat(sig, ",")
end

local function getOverloadedFunction(name: string, record: any): any
    local exactMatches = {}
    local complexMatches: { any } = {}
    local fallback = record.fallback

    for _, entry in ipairs(record.overloads) do
        local isComplex = false
        local sigParts = {}
        
        for _, part in ipairs(entry.expects) do
            if type(part) == "table" then
                isComplex = true
                break
            end
            table.insert(sigParts, part)
        end

        if isComplex then
            table.insert(complexMatches, entry)
        else
            local sigKey = table.concat(sigParts, ",")
            exactMatches[sigKey] = entry.callback
        end
    end

    local matchesDebug = {}
    for match in pairs(exactMatches) do
        table.insert(matchesDebug, match)
    end
    for _, entry in ipairs(complexMatches) do
        table.insert(matchesDebug, normalizeSignature(entry.expects))
    end

    return function<A, R...>(...: A): R...
        local args = table.pack(...)
        local count = args.n

        local sigKey = getSignature(args, count)
        local exact = exactMatches[sigKey]
        if exact then
            return (exact :: any)(...)
        end

        for _, entry in ipairs(complexMatches) do
            if #entry.expects ~= count then continue end
            
            local match = true
            for i = 1, count do
                if not matchSignature(args[i], entry.expects[i]) then
                    match = false
                    break
                end
            end
            
            if match and entry.callback then
                return (entry.callback :: any)(...)
            end
        end

        if fallback then
            return (fallback :: any)(...)
        end
        Log.NO_OVERLOAD_MATCH:throw(2, name, matchesDebug, sigKey)
    end
end

return getOverloadedFunction