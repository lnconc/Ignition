--!nocheck
-- State/Environment.lua

local Value = require(script.Parent.Value)
local Types = require(script.Parent.Types)
local is = require(script.Parent.is)
local env = require(script.Parent.Parent.Internal.env)

type PropertyDependencies<E> = Types.PropertyDependencies<E>
type PropertyEffect<T, E> = Types.PropertyEffect<T, E>
type Property<T> = Types.Property<T>
type CanBe<T> = Types.CanBe<T>
type ValueInternal<T> = Types.ValueInternal<T>
type PropertyFactory = <T, E>(effect: PropertyEffect<T, E>, dependencies: PropertyDependencies<E>) -> Property<T>

local ValueMetatable = getmetatable(Value.new(nil))
local Property: PropertyFactory
local areMetamethodsApplied = false

local function createBinaryOperator<T>(operator: (a: T, b: T) -> T): () -> Property<T>
    return function(a: CanBe<T>, b: CanBe<T>): Property<T>
        local is_a, is_b = is(a), is(b)
        return Property(function(use)
            local f_a, f_b = if is_a then use(a) else a, if is_b then use(b) else b
            return operator(f_a, f_b)
        end)
    end
end

local function createUnaryOperator<T>(operator: (a: T) -> T)
    return function(self: ValueInternal<T>): ValueInternal<T>
        return Property(function(use)
            return operator(use(self))
        end)
    end
end
local function createIterator<T>(self: ValueInternal<T>)
    local iterable = self._DANGEROUS_value
    assert(type(iterable) == "table", `attempt to iterate a {typeof(iterable)}`)
    return next, iterable, nil
end

return {
    InjectDependencies = function<E>(dependencies: PropertyDependencies<E>, effect: PropertyEffect<any, any>)
        env.set(effect, dependencies)
    end,
    ExposeProperty = function(factory: PropertyFactory)
        assert(not areMetamethodsApplied, `ExposeProperty can only be called once (Value metamethods initialization)`)
        areMetamethodsApplied = true
        Property = factory
        ValueMetatable.__eq = createBinaryOperator(function(a, b) return a == b
        end)
        ValueMetatable.__le = createBinaryOperator(function(a, b) return a <= b
        end)
        ValueMetatable.__lt = createBinaryOperator(function(a, b) return a < b
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
        ValueMetatable.__len = createUnaryOperator(function(a) return #a
        end)
        ValueMetatable.__iter = createIterator
    end
}