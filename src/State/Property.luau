--!strict
-- State/Property.lua

local Log = require("../Log")
local Value = require("./Value")
local createUse = require("./use")
local evaluate = require("./evaluate")
local Environment = require("./Environment")

local function Property<T>(effect: any, data: any?): any
    local property = (Value.new(nil) :: any)
    local latestDependencies = {}
    function property:evaluate<T>(): boolean
        local currentDependencies: { [any]: boolean } = {}
        local okay, newValueOrError = xpcall(effect, function(error: string)
            Log.REACTIVE_EVAL_FAIL:warn(error)
        end, createUse(currentDependencies), if data then unpack(data) else nil)
        if okay then
            self:set(newValueOrError)
        end
        local oldDependencies = latestDependencies
        latestDependencies = currentDependencies
        evaluate(self, latestDependencies, oldDependencies)
        return okay
    end
    property:evaluate()
    return property
end

Environment.ExposeProperty(Property)

return Property