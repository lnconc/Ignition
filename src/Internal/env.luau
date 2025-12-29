--!strict
-- Internal/env.lua

local Types = require("./Types")

type Function = Types.Function
type FunctionEnvironment = Types.FunctionEnvironment

return {
    set = function(fn: Function, environment: FunctionEnvironment)
        if type(fn) ~= "function" then return end
        assert(next(environment), "empty modified registry")
        local originalEnvironment = getfenv(fn)
        for key, value in environment do
            originalEnvironment[key] = value
        end
    end,
    get = function(closure): FunctionEnvironment
        return getfenv(closure)
    end
}