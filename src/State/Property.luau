--!strict
-- State/Property.lua

local Log = require("../Log")
local Types = require("./Types")
local Value = require("./Value")
local createUse = require("./use")
local evaluate = require("./evaluate")
local Environment = require("./Environment")

type Property<T> = Types.Property<T>
type GraphObject<T> = Types.GraphObject<T>
type Effect<T> = Types.Effect<T>
type InternalValue<T> = Types.InternalValue<T>
type GraphDependencies = Types.GraphDependencies
type Data = Types.Data

local function Property<T>(effect: Effect<T>, data: Data?): Property<T>
    local property = (Value.new(nil) :: any) :: InternalValue<T>
    local latestDependencies: GraphDependencies = {}
    function property.evaluate<T>(self: InternalValue<T>): boolean
        local currentDependencies: GraphDependencies = {}
        local okay, newValueOrError = xpcall(effect, function(error: string)
            Log.REACTIVE_EVAL_FAIL:warn(error)
        end, createUse(currentDependencies), if data then unpack(data) else nil)
        if okay then
            self:set(newValueOrError)
        end
        local oldDependencies: GraphDependencies = latestDependencies
        latestDependencies = currentDependencies
        evaluate(self, latestDependencies, oldDependencies)
        return okay
    end
    property:evaluate()
    return property :: any
end

Environment.ExposeProperty(Property :: any)

return Property