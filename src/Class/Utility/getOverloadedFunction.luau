--!strict
-- Class/Utility/getOverloadedFunction.lua

local Configuration = require("./Configuration")
local Types = require("../Types")

type OverloadRecord = Types.OverloadRecord
type OverloadEntry = Types.OverloadEntry

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

local function getSignature(args: { any }, count: number): string
    local sig = {}
    for i = 1, count do
        table.insert(sig, typeof(args[i]))
    end
    return table.concat(sig, ",")
end

local function getOverloadedFunction(name: string, record: OverloadRecord)
    local exactMatches = {}
    local complexMatches: { OverloadEntry } = {}
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

    return function(...: any): ...any
        local args = table.pack(...)
        local count = args.n

        local sigKey = getSignature(args, count)
        local exact = exactMatches[sigKey]
        if exact then
            return exact(...)
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
            
            if match then
                return entry.callback(...)
            end
        end

        if fallback then
            return fallback(...)
        end
        error(`No overload for method '{name}' matches the provided arguments`, 3)
    end
end

return getOverloadedFunction