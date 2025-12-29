--!strict
-- State/Observe.luau
local Types = require("./Types")
local Value = require("./Value")
local createUse = require("./use")
local evaluate = require("./evaluate")

type GraphObject<T> = Types.GraphObject<T>
type GraphDependencies = Types.GraphDependencies
type InternalValue<T> = Types.InternalValue<T>
type Observe = Types.Observe
type Effect<T> = Types.Effect<T>

local function Observe(callback: Effect<any>): Observe
    local observer = (Value.new(nil) :: any) :: InternalValue<any>
    local latestDependencies: GraphDependencies = {}

    function observer.evaluate(self: InternalValue<any>): boolean
        local currentDependencies: GraphDependencies = {}
        local okay = xpcall(callback, function(err: string)
            warn(`an error happened while attempting to evaluate state reactivity (error below)\n\n{err}`)
        end, createUse(currentDependencies))
        local oldDependencies = latestDependencies
        latestDependencies = currentDependencies
        evaluate(self, latestDependencies, oldDependencies)
        return okay
    end
    observer:evaluate()
    return function()
        observer:Destroy()
    end
end

return Observe