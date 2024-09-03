
local TypeDefinitions = require(script.Parent.TypeDefinitions)

local ReadWrite = {}
ReadWrite["Vector2"] = {
    ByteSize = 12,
    Write = function(writer: TypeDefinitions.BufferWriter, input: Vector2)
        writer:writefloat32(input.X)
        writer:writefloat32(input.Y)
    end,
    Read = function(reader: TypeDefinitions.BufferReader): Vector2
        return Vector2.new(
            reader:readfloat32(),
            reader:readfloat32()
        )
    end
}
ReadWrite["Vector3"] = {
    ByteSize = 12,
    Write = function(writer: TypeDefinitions.BufferWriter, input: Vector3)
        writer:writefloat32(input.X)
        writer:writefloat32(input.Y)
        writer:writefloat32(input.Z)
    end,
    Read = function(reader: TypeDefinitions.BufferReader): Vector3
        return Vector3.new(
            reader:readfloat32(),
            reader:readfloat32(),
            reader:readfloat32()
        )
    end
}
ReadWrite["CFrame"] = {
    ByteSize = 24,
    Write = function(writer: TypeDefinitions.BufferWriter, input: CFrame)
        local ry, rx, rz = input:ToEulerAnglesYXZ()
        ReadWrite.Vector3.Write(writer, input.Position)
        writer:writefloat32(ry)
        writer:writefloat32(rx)
        writer:writefloat32(rz)
    end,
    Read = function(reader: TypeDefinitions.BufferReader): CFrame
        return CFrame.new(ReadWrite.Vector3.Read(reader)) * CFrame.Angles(
            reader:readfloat32(),
            reader:readfloat32(),
            reader:readfloat32()
        )
    end
}


return {
    ReadWrite = ReadWrite,
}