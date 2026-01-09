--!strict
-- State/Observe.luau
local Log = require("../Log")
local Value = require("./Value")
local createUse = require("./use")
local evaluate = require("./evaluate")

local function Observe<T>(effect: any, data: any?): any
    local observer = (Value.new(nil) :: any) 
    local latestDependencies = {}

    function observer:evaluate(): boolean
        local currentDependencies: { [any]: boolean } = {}
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