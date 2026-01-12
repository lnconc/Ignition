--!strict
-- Class/libs/dumpsize.lua

local env = require("../../Internal/env")
local Registry = require("../Utility/Registry")
local StackSpider = require("../Utility/StackSpider") :: any
local anon = require("./anon") :: any

local function count(src: any): number
    local size = 0
    for _ in src do
        size += 1
    end
    return size
end

local function dumpsize(object: any?): string
    if object then
        local environment = Registry.GetEnvironment(object)
        if not environment or not environment.Context then
            return "-1"
        end
        
        local ctx: any = environment.Context
        local familySize = 0
        for _, inclusionMap in pairs(ctx.Family) do
            familySize += count(inclusionMap)
        end
        return `internal (includes): {count(ctx.Includes)}, internal (refs): {count(ctx.Refs)}, family: {familySize}, closures: {count(environment.Closures)}`
    end

    return `stackspider (within): {count(StackSpider.__withinCache)}, stackspider (access): {count(StackSpider.__accessCache)}, stackspider (resolution): {count(StackSpider.__resolutionCache)}, env: {count(env.__environments)}, anon: {count(anon.__cache)}`
end

return dumpsize