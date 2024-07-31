
local Types = require(script.Parent.Types)
local Utility = require(script.Parent.Utility)
local Datatypes = require(script.Parent.Datatypes)

local ReaderAPI = {}

local function read(method: string, size: number, self): number
    local _, add = Utility.AssertForBufferSize(size, self._cursor, self._buffSize)
    local out = buffer[`read{method}`](self._buffer, self._cursor)
    self._cursor += add
    return out
end

function ReaderAPI:readuint8(): number
    return read("u8", 1, self)
end

function ReaderAPI:readuint16(): number
    return read("u16", 2, self)
end

function ReaderAPI:readuint32(): number
    return read("u32", 4, self)
end

function ReaderAPI:readint8(): number
    return read("i8", 1, self)
end

function ReaderAPI:readint16(): number
    return read("i16", 2, self)
end

function ReaderAPI:readint32(): number
    return read("i32", 4, self)
end

function ReaderAPI:readfloat32(): number
    return read("f32", 4, self)
end

function ReaderAPI:readfloat64(): number
    return read("f64", 8, self)
end

function ReaderAPI:readnumber(): boolean
    local castSize = self:readuint8()
    local cast = self:readstringraw(castSize)
    return self[`read{cast}`](self)
end

function ReaderAPI:readstringraw(length: number): string
    local out = buffer.readstring(self._buffer, self._cursor, length)
    self._cursor += length
    return out
end

function ReaderAPI:readboolean(): boolean
    return self:readuint8() == 1
end

function ReaderAPI:readstring()
    local len = self:readnumber()
    local out = buffer.readstring(self._buffer, self._cursor, len)
    self._cursor += len
    return out
end

function ReaderAPI:readtable(truncateSize: number?): Types.table
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

function ReaderAPI:readdatatype(type: string): Types.Datatype
    local datatype = Datatypes[type]
    if not datatype then
        error(`datatype "{type}" is unsupported`)
    end
    return datatype.read(self)
end

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

function ReaderAPI:dumpread<T...>(): T...
    local out = {}
    local errorWhileReading = nil
    while self._cursor < self._buffSize do
        local ok, value = pcall(self.readauto, self)
        if not ok then
            errorWhileReading = value
            break
        end
        out[#out+1] = value
    end
    if errorWhileReading ~= nil then
        error(`unable to read buffer content, halted at position {self._cursor}; code ({errorWhileReading})`)
    end
    return table.unpack(out)
end

--[=[
@class Reader
]=]
local Reader = {}

local function buildBufferReader(buff: buffer)
    local self = {}
    self._cursor = 0
    self._buffer = buff
    self._buffSize = buffer.len(buff)
    setmetatable(self, {__index = ReaderAPI})
    return self
end

function Reader.new(buff: buffer | string)
    local type = typeof(buff)
    if type == "string" then
        return buildBufferReader(buffer.fromstring(buff))
    elseif type == "buffer" then
        return buildBufferReader(buff)
    else
        error(`invalid type to initialize BufferReader; expected string or buffer, got {type}`)
    end
end

return Reader