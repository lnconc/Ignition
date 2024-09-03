
local TypeDefinitions = require(script.Parent.TypeDefinitions)
local Utility = require(script.Parent.Utility)
local Datatypes = require(script.Parent.Datatypes)

local ReaderAPI = {}

local function read(method: string, size: number, self): number
    local out = buffer[`read{method}`](self._buffer, self._cursor)
    self._cursor += size
    return out
end

--[=[
@within BufferReader
]=]
function ReaderAPI:readuint8(): number
    return read("u8", 1, self)
end

--[=[
@within BufferReader
]=]
function ReaderAPI:readuint16(): number
    return read("u16", 2, self)
end

--[=[
@within BufferReader
]=]
function ReaderAPI:readuint32(): number
    return read("u32", 4, self)
end

--[=[
@within BufferReader
]=]
function ReaderAPI:readint8(): number
    return read("i8", 1, self)
end

--[=[
@within BufferReader
]=]
function ReaderAPI:readint16(): number
    return read("i16", 2, self)
end

--[=[
@within BufferReader
]=]
function ReaderAPI:readint32(): number
    return read("i32", 4, self)
end

--[=[
@within BufferReader
]=]
function ReaderAPI:readfloat32(): number
    return read("f32", 4, self)
end

--[=[
@within BufferReader
]=]
function ReaderAPI:readprecisefloat32(): number
    local placement = self:readuint8()
    local out = self:readfloat32()
    return if placement > 0 then Utility.Round(out, placement) else out
end

--[=[
@within BufferReader
]=]
function ReaderAPI:readfloat64(): number
    return read("f64", 8, self)
end

--[=[
@within BufferReader
]=]
function ReaderAPI:readprecisefloat64(): number
    local placement = self:readuint8()
    local out = self:readfloat64()
    return if placement > 0 then Utility.Round(out, placement) else out
end

--[=[
@within BufferReader
]=]
function ReaderAPI:readnumber(): boolean
    local castSize = self:readuint8()
    local cast = self:readstringraw(castSize)
    return self[`read{cast}`](self)
end

--[=[
@within BufferReader
]=]
function ReaderAPI:readstringraw(length: number): string
    local out = buffer.readstring(self._buffer, self._cursor, length)
    self._cursor += length
    return out
end

--[=[
@within BufferReader
]=]
function ReaderAPI:readboolean(): boolean
    return self:readuint8() == 1
end

--[=[
@within BufferReader
]=]
function ReaderAPI:readstring()
    local len = self:readuint16()
    local out = buffer.readstring(self._buffer, self._cursor, len)
    self._cursor += len
    return out
end

--[=[
@within BufferReader
@return table
]=]
function ReaderAPI:readtable(truncateSize: number?): TypeDefinitions.table
    local out = {}
    local size = self:readuint16()
    if type(truncateSize) == "number" then
        size = math.min(size, truncateSize)
    end
    for _ = 1, size do
        local key = self:readauto()
        local value = self:readauto()
        out[key] = value
    end
    return out
end

--[=[
@within BufferReader
@return Datatype
]=]
function ReaderAPI:readdatatype(type: string): TypeDefinitions.Datatype
    local datatype = Datatypes.ReadWrite[type]
    if not datatype then
        error(`datatype "{type}" is unsupported`, 3)
    end
    return datatype.Read(self)
end

--[=[
@within BufferReader
]=]
function ReaderAPI:readauto()
    local typeLen = self:readuint8()
    local type = self:readstringraw(typeLen)
    if type == "number" then
        return self:readnumber()
    elseif type == "string" then
        return self:readstring()
    elseif type == "boolean" then
        return self:readboolean()
    elseif type == "table" then
        return self:readtable()
    else
        return self:readdatatype(type)
    end
end

--[=[
@class BufferReader
@__index ReaderAPI
]=]
local Reader = {}
local function buildBufferReader(buff: buffer): TypeDefinitions.BufferReader
    local self = {}
    self._cursor = 0
    self._buffer = buff
    self._size = buffer.len(buff)
    setmetatable(self, {__index = ReaderAPI})
    return self
end

--[=[
@within BufferReader
@param buff buffer | string
@return BufferReader

Allows for a more comfortable way to read values stored inside a buffer.
]=]
function Reader.new(buff: buffer | string): TypeDefinitions.BufferReader
    local type = typeof(buff)
    if type == "string" then
        return buildBufferReader(buffer.fromstring(buff))
    elseif type == "buffer" then
        return buildBufferReader(buff)
    else
        error(`invalid type to initialize BufferReader; expected string or buffer, got {type}`, 3)
    end
end

--[=[
@within BufferReader
@param buff buffer
@return ... any

Automatically translate values stored in the target buffer as readable data.
Using this with a buffer not initialized by `BufferWriter.dump()` would result in an error.
]=]
function Reader.fromdump(buff: buffer): ...any
    local reader = Reader.new(buff)
    local out = {}
    if not reader:readstringraw(reader:readuint8()) then
        error("the provided buffer is not initialized with BufferWriter.dump", 3)
    end
    local errorWhileReading = nil
    while reader._cursor < reader._size do
        local ok, value = pcall(reader.readauto, reader)
        if not ok then
            errorWhileReading = value
            break
        end
        out[#out+1] = value
    end
    if errorWhileReading ~= nil then
        error(`unable to read buffer content, halted at position {reader._cursor}; code ({errorWhileReading})`, 3)
    end
    return table.unpack(out)
end

return Reader