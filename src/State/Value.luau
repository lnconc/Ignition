--!strict
-- State/Value.lua

local Log = require("../Log")
local Types = require("./Types")
type Value<T> = Types.Value<T>
type InternalValue<T> = Types.InternalValue<T>

local ValueMetatable = {}
ValueMetatable.__index = ValueMetatable
ValueMetatable.__tostring = function(self: InternalValue<any>)
    return `Value<{self._DANGEROUS_value}>`
end

function ValueMetatable.set<T>(self: InternalValue<T>, value: T)
    if self._CONSTANT_locked then
        Log.CONSTANT_SET:throw(2, typeof(self._DANGEROUS_value), typeof(value))
    end
    if self._DANGEROUS_value == value then return end
    self._DANGEROUS_value = value
    for dep in pairs(self._dependencies) do
        dep:evaluate()
    end
end

function ValueMetatable.evaluate<T>(_self: InternalValue<T>): boolean
    return true
end

function ValueMetatable.Destroy<T>(self: InternalValue<T>)
    if self._destructor then
        self._destructor(self._DANGEROUS_value)
    end
    self._DANGEROUS_value = nil
    for dependent in pairs(self._dependents) do
        dependent._dependencies[self] = nil
    end
    table.clear(self :: { [any]: any })
    setmetatable(self, nil)    
end

local Value = {}
function Value.new<T>(defaultValue: T, destructor: (obj: T) -> ()?): Value<T>
    if (typeof(defaultValue) == "Instance" or
            (type(defaultValue) == "table" and getmetatable(defaultValue) ~= nil) and
            type((defaultValue :: any).Destroy) ~= "function"
        ) and destructor == nil
    then
        Log.INST_WRAPPER_NO_DEST:warn()
    end
    local self = {}
    self._destructor = destructor
    self._DANGEROUS_value = defaultValue
    self._CONSTANT_locked = false
    self._CONSTANT_error_msg = nil
    self._dependencies = {}
    self._dependents = {} -- used to unset if we are destroyed
    setmetatable(self, ValueMetatable)
    return self :: Value<T>
end

return Value