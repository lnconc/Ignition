--!strict
-- State/Observe.luau
local Log = require("../Log")
local Types = require("./Types")
local Value = require("./Value")
local createUse = require("./use")
local evaluate = require("./evaluate")

type GraphObject<T> = Types.GraphObject<T>
type GraphDependencies = Types.GraphDependencies
type Data = Types.Data
type InternalValue<T> = Types.InternalValue<T>
type Observe = Types.Observe
type Effect<T> = Types.Effect<T>

local function Observe<T>(effect: Effect<T>, data: Data?): Observe
    local observer = (Value.new(nil) :: any) :: InternalValue<any>
    local latestDependencies: GraphDependencies = {}

    function observer.evaluate(self: InternalValue<any>): boolean
        local currentDependencies: GraphDependencies = {}
        local okay = xpcall(effect, function(err: string)
            Log.REACTIVE_EVAL_FAIL:warn(err)
        end, createUse(currentDependencies), if data then unpack(data) else nil)
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