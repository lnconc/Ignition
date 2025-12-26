--!nocheck
-- Modules/Ser.lua

export type TypeData = any 
export type Serialized<T = any> = {
    type: string,
    data: TypeData,
    sign: string?
}
type table = typeof({})
type PreSerialized<T> = { any } | T
type Processor = {
    encode: (input: any, seen: { [any]: any }?) -> any,
    decode: (data: any) -> any
}

local NATIVE_DATATYPES = { ["string"] = true, ["number"] = true, ["boolean"] = true }
local SER_SIGNATURE = "#$"

local Ser = {}
local SerDatatypes: { [string]: Processor } = {}

local function serialize_data(datatype: any, seen: { [any]: any }?): any
    local _datatype = typeof(datatype)
    if NATIVE_DATATYPES[_datatype] then
        return datatype
    end
    
    local ser = SerDatatypes[_datatype]
    assert(ser, `[Ser] datatype "{_datatype}" could not be serialized.`)
    
    return {
        type = _datatype,
        data = ser.encode(datatype, seen),
        sign = SER_SIGNATURE
    }
end

local function deserialize_data(raw: any): any
    local rawType = type(raw)
    if NATIVE_DATATYPES[rawType] then
        return raw
    end
    
    if type(raw) == "table" and raw.sign == SER_SIGNATURE then
        local processor = SerDatatypes[raw.type]
        assert(processor, `[Ser] datatype "{raw.type}" does not exist.`)
        return processor.decode(raw.data)
    elseif rawType == "table" then
        return SerDatatypes.table.decode(raw)
    else
        error(`[Ser] datatype for input "{raw}" does not exist`, 2)
    end
end

local function serialize_table(tbl: table, _seen: table?)
    local seen = _seen or {}
    if seen[tbl] then
        error("Cycle detected during serialization")
    end
    seen[tbl] = true

    local result = {}
    for key, value in pairs(tbl) do
        local serializedKey = serialize_data(key, seen)
        local serializedValue = serialize_data(value, seen)
        result[serializedKey] = serializedValue
    end

    seen[tbl] = nil
    return result
end

SerDatatypes['nil'] = {
    encode = function(_input: nil): nil
        return nil
    end,
    decode = function(_data: TypeData): nil
        return nil
    end
}
SerDatatypes['table'] = {
    encode = function(input: table, seen: table?): PreSerialized<table>
        return serialize_table(input, seen)
    end,
    decode = function(data: TypeData): table
        return Ser.deep_deserialize(data)
    end
}
SerDatatypes['UDim'] = {
    encode = function(input: UDim): PreSerialized<UDim>
        return { input.Scale, input.Offset }
    end,
    decode = function(data: TypeData): UDim
        return UDim.new(data[1], data[2])
    end
}
SerDatatypes['UDim2'] = {
    encode = function(input: UDim2): PreSerialized<UDim2>
        return { x = SerDatatypes.UDim.encode(input.X), y = SerDatatypes.UDim.encode(input.Y) }
    end,
    decode = function(data: TypeData): UDim2
        return UDim2.new(SerDatatypes.UDim.decode(data.x), SerDatatypes.UDim.decode(data.y))
    end
}
SerDatatypes['Rect'] = {
    encode = function(input: Rect): PreSerialized<Rect>
        return { min = SerDatatypes.Vector2.encode(input.Min), max = SerDatatypes.Vector2.encode(input.Max) }
    end,
    decode = function(data: TypeData): Rect
        return Rect.new(SerDatatypes.Vector2.decode(data.min), SerDatatypes.Vector2.decode(data.max))
    end
}
SerDatatypes['DateTime'] = {
    encode = function(input: DateTime): PreSerialized<DateTime>
        return { input.UnixTimestampMillis }
    end,
    decode = function(data: TypeData): DateTime
        return DateTime.fromUnixTimestampMillis(data[1])
    end
}
SerDatatypes['Vector3'] = {
    encode = function(input: Vector3): PreSerialized<Vector3>
        return { input.X, input.Y, input.Z }
    end,
    decode = function(data: TypeData): Vector3
        return Vector3.new(data[1], data[2], data[3])
    end
}
SerDatatypes['Vector3int16'] = {
    encode = function(input: Vector3int16): PreSerialized<Vector3int16>
        return { input.X, input.Y, input.Z }
    end,
    decode = function(data: TypeData): Vector3int16
        return Vector3int16.new(data[1], data[2], data[3])
    end
}
SerDatatypes['Vector2'] = {
    encode = function(input: Vector2): PreSerialized<Vector2>
        return { input.X, input.Y }
    end,
    decode = function(data: TypeData): Vector2
        return Vector2.new(data[1], data[2])
    end
}
SerDatatypes['Vector2int16'] = {
    encode = function(input: Vector2int16): PreSerialized<Vector2int16>
        return { input.X, input.Y }
    end,
    decode = function(data: TypeData): Vector2int16
        return Vector2int16.new(data[1], data[2])
    end
}
SerDatatypes['CFrame'] = {
    encode = function(input: CFrame): PreSerialized<CFrame>
        return {
            position = SerDatatypes.Vector3.encode(input.Position),
            right = SerDatatypes.Vector3.encode(input.RightVector),
            up = SerDatatypes.Vector3.encode(input.UpVector),
            look = SerDatatypes.Vector3.encode(input.LookVector),
        }
    end,
    decode = function(data: TypeData): CFrame
        return CFrame.fromMatrix(
            SerDatatypes.Vector3.decode(data.position),
            SerDatatypes.Vector3.decode(data.right),
            SerDatatypes.Vector3.decode(data.up),
            SerDatatypes.Vector3.decode(data.look)
        )
    end
}
SerDatatypes['Color3'] = {
    encode = function(input: Color3): PreSerialized<string>
        return input:ToHex()
    end,
    decode = function(data: TypeData): Color3
        return Color3.fromHex(data)
    end
}
SerDatatypes['BrickColor'] = {
    encode = function(input: BrickColor): PreSerialized<BrickColor>
        return SerDatatypes.Color3.encode(input.Color)
    end,
    decode = function(data: TypeData): BrickColor
        return BrickColor.new(SerDatatypes.Color3.decode(data))
    end
}
SerDatatypes['Ray'] = {
    encode = function(input: Ray): PreSerialized<Ray>
        return { origin = SerDatatypes.Vector3.encode(input.Origin), direction = SerDatatypes.Vector3.encode(input.Direction) }
    end,
    decode = function(data: TypeData): Ray
        return Ray.new(SerDatatypes.Vector3.decode(data.origin), SerDatatypes.Vector3.decode(data.direction))
    end
}
SerDatatypes['Region3'] = {
    encode = function(input: Region3): PreSerialized<Region3>
        local pos = input.CFrame.Position
        local sizeHalf = input.Size * 0.5
        local min = pos - sizeHalf
        local max = pos + sizeHalf
        return { min = SerDatatypes.Vector3.encode(min), max = SerDatatypes.Vector3.encode(max) }
    end,
    decode = function(data: TypeData): Region3
        return Region3.new(SerDatatypes.Vector3.decode(data.min), SerDatatypes.Vector3.decode(data.max))
    end
}
SerDatatypes['Region3int16'] = {
    encode = function(input: Region3int16): PreSerialized<Region3int16>
        return { min = SerDatatypes.Vector3.encode(input.Min), max = SerDatatypes.Vector3.encode(input.Max) }
    end,
    decode = function(data: TypeData): Region3int16
        return Region3int16.new(SerDatatypes.Vector3.decode(data.min), SerDatatypes.Vector3.decode(data.max))
    end
}
SerDatatypes['Enum'] = {
    encode = function(input: Enum): PreSerialized<string>
        return tostring(input)
    end,
    decode = function(data: TypeData): Enum
        return Enum[data]
    end
}
SerDatatypes['EnumItem'] = {
    encode = function(input: EnumItem): PreSerialized<EnumItem>
        return { enum = tostring(input.EnumType), value = input.Name }
    end,
    decode = function(data: TypeData): EnumItem
        return Enum[data.enum][data.value]
    end
}
SerDatatypes['Font'] = {
    encode = function(input: Font): PreSerialized<Font>
        return { family = input.Family, weight = SerDatatypes.EnumItem.encode(input.Weight), style = SerDatatypes.EnumItem.encode(input.Style) }
    end,
    decode = function(data: TypeData): Font
        return Font.new(data.family, data.weight, data.style )
    end
}
SerDatatypes['PhysicalProperties'] = {
    encode = function(input: PhysicalProperties): PreSerialized<PhysicalProperties>
        return { input.Density, input.Friction, input.Elasticity, input.FrictionWeight, input.ElasticityWeight }
    end,
    decode = function(data: TypeData): PhysicalProperties
        return PhysicalProperties.new(table.unpack(data))
    end
}
SerDatatypes['PathWaypoint'] = {
    encode = function(input: PathWaypoint): PreSerialized<PathWaypoint>
        return { position = SerDatatypes.Vector3.encode(input.Position), action = SerDatatypes.EnumItem.encode(input.Action) }
    end,
    decode = function(data: TypeData): PathWaypoint
        return PathWaypoint.new(SerDatatypes.Vector3.decode(data.position), SerDatatypes.Vector3.decode(data.action))
    end
}
SerDatatypes['TweenInfo'] = {
    encode = function(input: TweenInfo): PreSerialized<TweenInfo>
        return {
            time = input.Time,
            delayTime = input.DelayTime,
            repeatCount = input.RepeatCount,
            reverses = input.Reverses,
            easingDirection = SerDatatypes.EnumItem.encode(input.EasingDirection),
            easingStyle = SerDatatypes.EnumItem.encode(input.EasingStyle),
        }
    end,
    decode = function(data: TypeData): TweenInfo
        return TweenInfo.new(
            data.time,
            SerDatatypes.EnumItem.decode(data.easingStyle),
            SerDatatypes.EnumItem.decode(data.easingDirection),
            data.repeatCount,
            data.reverses,
            data.delayTime
        )
    end
}

Ser.serialize = function<T>(datatype: T): Serialized<T> | T
    return serialize_data(datatype)
end
Ser.deserialize = deserialize_data
Ser.can = function<T>(input: any): boolean
    return NATIVE_DATATYPES[input]or SerDatatypes[typeof(input)] ~= nil
end
Ser.compare = function<A, B>(a: Serialized<A>, b: Serialized<B>): boolean
    local canCompareA, canCompareB = Ser.can(a), Ser.can(b)
    if canCompareA and canCompareB then
        local data_comparison_ok = true
        for k, v in a.data do
            if b[k] ~= v then
                data_comparison_ok = false
                break
            end
        end
        return data_comparison_ok and (a.type == b.type)
    elseif not (canCompareA and canCompareB) then
        return a ~= b
    else
        error("[Ser] incompatible comparison check (argument 'a' or argument 'b' might be different types, ie. argument 'a' might be a primitive datatype meanwhile argument 'b' might be a Ser type", 2)
    end
end

Ser.sign = function(input: any): boolean
    return type(input) == "table" and input.sign == SER_SIGNATURE
end

Ser.deep_serialize = function(input: { [any]: any }): { [any]: any }
    local serialized = {}
    for key, value in input do
        serialized[serialize_data(key)] = serialize_data(value)
    end
    return serialized
end

Ser.deep_deserialize = function(serialized: { [any]: any }): { [any]: any }
    local raw = {}
    for key, value in serialized do
        raw[deserialize_data(key)] = deserialize_data(value)
    end
    return raw
end

return Ser