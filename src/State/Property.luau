--!strict
-- State/Property.lua

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
type Dependencies = Types.Dependencies

local function Property<T>(effect: Effect<T>, dependencies: Dependencies?): Property<T>
    local property = (Value.new(nil) :: any) :: InternalValue<T>
    local latestDependencies: GraphDependencies = {}
    function property.evaluate<T>(self: InternalValue<T>): boolean
        local currentDependencies: GraphDependencies = {}
        local okay, newValueOrError = xpcall(effect, function(error: string)
            warn(`an error happened while attempting to evaluate state reactivity (error below)\n\n{error}`)
        end, createUse(currentDependencies))
        if okay then
            self:set(newValueOrError)
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