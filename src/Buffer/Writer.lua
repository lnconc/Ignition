
local Types = require(script.Parent.Types)
local Utility = require(script.Parent.Utility)
local Datatypes = require(script.Parent.Datatypes)

local WriterAPI = {}

local function write(method: string, size: number, input: number, self)
    local position, add = Utility.AssertForBufferSize(size, self._cursor, self._buffSize)
    Utility.ResizeBufferTo(self._buffer, position)
    buffer[`write{method}`](self._buffer, self._cursor, input)
    self._cursor += add
end

function WriterAPI:writeuint8(input: number)
    write("u8", 1, input, self)
end

function WriterAPI:writeuint16(input: number)
    write("u16", 2, input, self)
end

function WriterAPI:writeuint32(input: number)
    write("u32", 4, input, self)
end

function WriterAPI:writeint8(input: number)
    write("i8", 1, input, self)
end

function WriterAPI:writeint16(input: number)
    write("i16", 2, input, self)
end

function WriterAPI:writeint32(input: number)
    write("i32", 4, input, self)
end

function WriterAPI:writefloat32(input: number)
    write("f32", 4, input, self)
end

function WriterAPI:writefloat64(input: number)
    write("f64", 8, input, self)
end

function WriterAPI:writenumber(input: number)
    local cast = Utility.AssumeNumberType(input)
    self:writeuint8(#cast)
    self:writestringraw(cast)
    self[`write{cast}`](self, input)
end

function WriterAPI:writestringraw(input: string, length: number?)
	local len = if length then math.min(#input, length) else #input
    Utility.ResizeBufferTo(self._buffer, len)
    buffer.writestring(self._buffer, self._cursor, input, len)
    self._cursor += len
end

function WriterAPI:writeboolean(input: boolean)
    self:writeuint8(if input == true then 1 else 0)
end

function WriterAPI:writestring(input: string, length: number?)
	local len = if length then math.min(#input, length) else #input
    local size = len + 4
    Utility.ResizeBufferTo(self._buffer, size)
    self:writenumber(len)
    buffer.writestring(self._buffer, self._cursor+4, input, length)
    self._cursor += len
end

function WriterAPI:writetable(input: Types.table)
    local count = 0
    local keys, values = {}, {}
    for key, value in next, input do
        count += 1
        keys[count] = key
        values[count] = value
    end
    self:writeuint16(count)
    for index = 1, count do
        self:writeauto(keys[index])
        self:writeauto(values[index])
    end
end

function WriterAPI:writedatatype(input: Types.Datatype)
    local type = typeof(input)
    local datatype = Datatypes[type]
    if not datatype then
        error(`datatype "{type}" is unsupported`)
    end
    datatype.write(self, input)
end

function WriterAPI:writeauto(input: any)
    local type = typeof(input)
    local len = #type
    self:writeuint8(len)
    self:writestringraw(type, len)
    if type == "number" then
        self:writenumber(input)
    elseif type == "string" then
        self:writestring(input)
    elseif type == "boolean" then
        self:writeboolean(input)
    elseif type == "table" then
        self:writetable(input)
    else
        self:writedatatype(input)
    end
end

function WriterAPI:getbuffer(tostring: boolean?): buffer -- self terminating once we get it
    local buff = self._buffer
    self._buffer = nil
    self._size = nil
    self._cursor = nil
    setmetatable(self, nil)
    return if tostring == true then buffer.tostring(buff) else buff
end

local Writer = {}
function Writer.new(size: number): Types.BufferWriter
    local self = {}
    self._buffer = buffer.create(size)
    self._size = size
    self._cursor = 0
    setmetatable(self, {__index = WriterAPI})
    return self
end

return Writer