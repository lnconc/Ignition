--!strict
-- Class/libs/dumpsize.lua

local env = require("../../Internal/env")
local StackSpider = require("../Utility/StackSpider") :: any
local anon = require("./anon") :: any

local function dumpsize(): string
    local function count(src: any): number
        local size = 0
        for _ in src do
            size += 1
        end
        return size
    end
    return `stackspider (access): {count(StackSpider.__accessCache)}, stackspider (resolution): {count(StackSpider.__resolutionCache)}, env: {count(env.__environments)}, anon: {count(anon.__cache)}`
end

return dumpsize