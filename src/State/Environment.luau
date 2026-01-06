--!strict
-- State/Environment.lua

local Value = require("./Value")
local Types = require("./Types")
local is = require("./is")
local Log = require("../Log")

type Effect<T> = Types.Effect<T>
type Property<T> = Types.Property<T>
type CanBe<T> = Types.CanBe<T>
type InternalValue<T> = Types.InternalValue<T>
type Data = Types.Data
type PropertyFactory = <T>(effect: Effect<T>, data: Data?) -> Property<T>
type table = typeof({})

local ValueMetatable: any = getmetatable(Value.new("something"))
local Property: PropertyFactory
local areMetamethodsApplied = false

local function createBinaryOperator<T>(operator: (a: T, b: T) -> T): (a: CanBe<T>, b: CanBe<T>) -> Property<T>
    return function(a: CanBe<T>, b: CanBe<T>): Property<T>
        local is_a, is_b = is(a), is(b)
        return Property(function(use)
            local f_a, f_b = if is_a then use(a) else a, if is_b then use(b) else b
            return operator(f_a, f_b)
        end)
    end
end

local function createUnaryOperator<T>(operator: (a: T) -> T): (self: Property<T>) -> Property<T>
    return function(self: Property<T>): Property<T>
        return Property(function(use)
            return operator(use(self))
        end)
    end
end
local function createIterator<T>(self: InternalValue<T>)
    local iterable = self._DANGEROUS_value
    assert(type(iterable) == "table", `attempt to iterate a {typeof(iterable)}`)
    return next, iterable, nil
end

return {
    ExposeProperty = function(factory: PropertyFactory)
        if areMetamethodsApplied then
            Log.EXPOSE_CALLED_TWICE:throw(2)
        end
        areMetamethodsApplied = true
        Property = factory
        ValueMetatable.__eq = createBinaryOperator(function(a, b) return a == b
        end)
        ValueMetatable.__le = createBinaryOperator(function(a, b) return (a :: number) <= (b :: number)
        end)
        ValueMetatable.__lt = createBinaryOperator(function(a, b) return (a :: number) < (b :: number)
        end)
        ValueMetatable.__add = createBinaryOperator(function(a, b) return a + b
        end)
        ValueMetatable.__sub = createBinaryOperator(function(a, b) return a - b
        end)
        ValueMetatable.__mul = createBinaryOperator(function(a, b)return a * b
        end)
        ValueMetatable.__div = createBinaryOperator(function(a, b) return a / b
        end)
        ValueMetatable.__idiv = createBinaryOperator(function(a, b) return a // b
        end)
        ValueMetatable.__mod = createBinaryOperator(function(a, b) return a % b
        end)
        ValueMetatable.__pow = createBinaryOperator(function(a, b) return a ^ b
        end)
        ValueMetatable.__unm = createUnaryOperator(function(a) return -a
        end)
        ValueMetatable.__concat = createBinaryOperator(function(a, b) return a .. b
        end)
        ValueMetatable.__len = createUnaryOperator(function(a) return #(a :: table)
        end)
        ValueMetatable.__iter = createIterator
    end
}