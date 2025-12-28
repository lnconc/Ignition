--!nocheck
-- State/Property.lua

local Types = require("./Types")
local Value = require("./Value")
local createUse = require("./use")
local evaluate = require("./evaluate")
local Environment = require("./Environment")

type Property<T> = Types.Property<T>
type GraphObject<T> = Types.GraphObject<T>
type PropertyEffect<T> = Types.PropertyEffect<T>
type ValueFull<T> = Types.ValueFull<T>
type GraphDependencies = Types.GraphDependencies

local function Property<T, E>(effect: PropertyEffect<T>, dependencies: { [string]: any }): Property<T>
    local property = Value.new(nil)
    local latestDependencies: GraphDependencies = {}
    function property.evaluate<T>(self: ValueFull<T>): boolean
        local currentDependencies: GraphDependencies = {}
        local okay, newValueOrError = xpcall(effect, function(error: string)
            warn(`an attempting to evaluate state reactivity (error below)\n\n{error}`)
        end, createUse(currentDependencies))
        if okay then
            (self :: { set: (self: ValueFull<T>, value: T) -> ()}):set(newValueOrError)
        end
        local oldDependencies: GraphDependencies = latestDependencies
        latestDependencies = currentDependencies
        evaluate(self, latestDependencies, oldDependencies)
        return okay
    end
    if type(dependencies) == "table" and next(dependencies) ~= nil then
        Environment.InjectDependencies(dependencies, effect)
    end
    property:evaluate()
    return property
end

Environment.ExposeProperty(Property)

return Property