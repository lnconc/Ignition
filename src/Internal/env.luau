--!strict
-- Internal/env.lua

local Types = require("./Types")

type Function = Types.Function
type FunctionEnvironment = Types.FunctionEnvironment

local Environments: { [Function]: FunctionEnvironment } = setmetatable({}, { __mode = "k" })

local function getenv(fn: Function): FunctionEnvironment
    local env = Environments[fn]
    if not env then
        env = {}
        Environments[fn] = env
    end
    return env
end

return {
    set = function(fn, environment: FunctionEnvironment)
        if type(fn) ~= "function" then return end
        assert(next(environment), "empty modified registry")
        local originalEnvironment = getenv(fn)
        for key, value in environment do
            originalEnvironment[key] = value
        end
    end,
    get = function(closure): FunctionEnvironment
        return getenv(closure)
    end,
    delete = function(closure)
        Environments[closure] = nil
    end,
    __environments = Environments,
}