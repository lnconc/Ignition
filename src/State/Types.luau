--!strict
-- State/Types.lua

export type Value<T> = {
    set: (self: Value<T>, newValue: T) -> (),
    Destroy: (self: Value<T>) -> (),
    _DANGEROUS_value: T,
}

export type Property<T> = {
    Destroy: (self: Property<T>) -> (),
}

export type CanBe<T> = Value<T> | T

export type function GetProperty(value: type): type
    if value:is("table") then
        local val = value:readproperty(types.singleton("_DANGEROUS_value"))
        if val then return val end
    end
    return value
end

export type State = {
    Value: <T>(defaultValue: T, optionalDestructor: ((value: T) -> ())?) -> Value<T>,
    peek: <T>(value: CanBe<T>) -> GetProperty<T>,
    Observe: <T, U>(effect: <T0, U0...>(use: <T1>(value: T1) -> T1, U0...) -> T0, data: U) -> () -> (),
    Property: <T, U>(effect: <T0, U0...>(use: <T1>(value: T1) -> T1, U0...) -> T0, data: U) -> Property<T>,
}

return {}