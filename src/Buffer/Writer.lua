
local TypeDefinitions = require(script.Parent.TypeDefinitions)
local Utility = require(script.Parent.Utility)
local Datatypes = require(script.Parent.Datatypes)

local IDENTIFIER_CONTEXT = Utility.BufferFromDumpIdentifier:getcontext()
local IDENTIFIER_CONTEXT_LENGTH = #IDENTIFIER_CONTEXT

local WriterAPI = {}

local function write(method: string, size: number, input: number, self)
    Utility.ResizeBufferTo(self, self._cursor+size)
    buffer[`write{method}`](self._buffer, self._cursor, input)
    self._cursor += size
end

--[=[
@within BufferWriter
]=]
function WriterAPI:writeuint8(input: number)
    write("u8", 1, input, self)
end

--[=[
@within BufferWriter
]=]
function WriterAPI:writeuint16(input: number)
    write("u16", 2, input, self)
end

--[=[
@within BufferWriter
]=]
function WriterAPI:writeuint32(input: number)
    write("u32", 4, input, self)
end

--[=[
@within BufferWriter
]=]
function WriterAPI:writeint8(input: number)
    write("i8", 1, input, self)
end

--[=[
@within BufferWriter
]=]
function WriterAPI:writeint16(input: number)
    write("i16", 2, input, self)
end

--[=[
@within BufferWriter
]=]
function WriterAPI:writeint32(input: number)
    write("i32", 4, input, self)
end

--[=[
@within BufferWriter
]=]
function WriterAPI:writefloat32(input: number)
    write("f32", 4, input, self)
end

--[=[
@within BufferWriter
Like `BufferWriter:writefloat32()` but alleviates floating point rounding errors. Takes up slightly more space.
]=]
function WriterAPI:writeprecisefloat32(input: number)
    local dec = string.split(tostring(input), '.')[2]
    self:writeuint8(if dec then #dec else 0) -- find decimal placement
    self:writefloat32(input)
end

--[=[
@within BufferWriter
]=]
function WriterAPI:writefloat64(input: number)
    write("f64", 8, input, self)
end

--[=[
@within BufferWriter
Like `BufferWriter:writeprecisefloat64()` but alleviates floating point rounding errors. Takes up slightly more space.
]=]
function WriterAPI:writeprecisefloat64(input: number)
    local dec = string.split(tostring(input), '.')[2]
    self:writeuint8(if dec then #dec else 0) -- find decimal placement
    self:writefloat64(input)
end


--[=[
@within BufferWriter
Allows storage of a number without concerning of what type of cast it is.
Takes up a small, insignificant space but noticeable when used multiple times.
]=]
function WriterAPI:writenumber(input: number): number
    local cast, size = Utility.AssumeNumberType(input, self.AutomaticPreciseFloats)
    self:writeuint8(#cast)
    self:writestringraw(cast)
    self[`write{cast}`](self, input)
    return size / 8 -- offset
end

--[=[
@within BufferWriter
]=]
function WriterAPI:writestringraw(input: string, length: number?)
	local len = if length then math.min(#input, length) else #input
    Utility.ResizeBufferTo(self, len)
    buffer.writestring(self._buffer, self._cursor, input, length)
    self._cursor += len
end

--[=[
@within BufferWriter
]=]
function WriterAPI:writeboolean(input: boolean)
    self:writeuint8(if input == true then 1 else 0)
end

--[=[
@within BufferWriter
:::caution
String length limits at 65,535 characters
:::
]=]
function WriterAPI:writestring(input: string, length: number?)
	local len = if length then math.min(#input, length) else #input
    len = math.min(len, 65535)
    local size = len + 2
    Utility.ResizeBufferTo(self, size)
    buffer.writeu16(self._buffer, self._cursor, len)
    buffer.writestring(self._buffer, self._cursor+2, input, length)
    self._cursor += size
end

--[=[
@within BufferWriter
Allows storage of a table, both arrays and dictionaries—or both.
Uses `BufferWriter:writeauto()` however, so it does take a considerable amount of space.
@param input table
]=]
function WriterAPI:writetable(input: TypeDefinitions.table)
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

--[=[
@within BufferWriter
Allows storage of a Roblox Datatype; see TypeDefinitions→Datatype for supported datatypes.
@param input Datatype
]=]
function WriterAPI:writedatatype(input: TypeDefinitions.Datatype)
    local type = typeof(input)
    local datatype = Datatypes.ReadWrite[type]
    if not datatype then
        error(`datatype "{type}" is unsupported`, 3)
    end
    datatype.Write(self, input)
end

--[=[
@within BufferWriter
Automatically writes the given input—this however takes in more space by allocating what datatype is provided.
:::note
Providing numbers as input would take in much more space as it uses the `BufferWriter:writenumber()` method.
:::
]=]
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

--[=[
@within BufferWriter
Retrieve the internal buffer used for writing. Internally shrinks and truncates unneccessary space.
Optionally convert it to a string.
:::caution
Once retrieved, the writer undergoes cleaning—basically performing a `:Destroy()` behavior once this method is called.
:::
]=]
function WriterAPI:getbuffer(tostring: boolean?): buffer -- self terminating once we get it
    local buff = self._buffer
    self._buffer = nil
    self._size = nil
    self._cursor = nil
    setmetatable(self, nil)
    if tostring then
        buff = buffer.tostring(buff)
        return buff
    end
    return buff
end

--[=[
@class BufferWriter
@__index WriterAPI
]=]
local Writer = {}

--[=[
Create a customizable buffer template from the given `size`.
Allows for a more comfortable way to write and store values in a buffer.
:::info
The buffer automatically resizes itself, allowing you to go past the given `size` parameter.
However, you are expected and committed to strictly have a set size for normal conventions—but it is still by your preferences whether you want it strictly sized or not.
:::
@return BufferWriter
@within BufferWriter
]=]
function Writer.new(size: number): TypeDefinitions.BufferWriter
    local self = {}
    --[=[
    @prop AutomaticPreciseFloats boolean
    Setting to `true` would make `BufferWriter:writenumber()`'s utilization of `BufferUtility.AssumeNumberType()` assume that numbers identified as `floats` would have itself use `BufferWriter:writeprecisefloatx()` instead of `BufferWriter:writefloatx()`.
    @within BufferWriter
    ]=]
    self.AutomaticPreciseFloats = false
    self._buffer = buffer.create(size)
    self._size = size
    self._cursor = 0
    setmetatable(self, {__index = WriterAPI})
    return self
end

--[=[
Create a buffer out of the given datatypes passed.
Best used with `BufferReader.fromdump(buff)`
:::note
This function automatically transforms and condenses the provided arguments into a buffer, alleviating you from manually translating them traditionally.
However, this does takes up more space as it utilizes the `BufferWriter:writeauto()` method.
:::
@within BufferWriter
]=]
function Writer.dump(preciseFloats: boolean?): (...any) -> (tostring: boolean) -> buffer
    return function(...: any): (tostring: boolean) -> buffer
        local values = table.pack(...)
        local size = IDENTIFIER_CONTEXT_LENGTH+1
        for n = 1, values.n do
            local value = values[n]
            local type = typeof(value)
            local bytes, out = Utility.GetByteSize(value)
            size += bytes + #type + 1 --account the writeuint8(#len) and writerawstring(len) part in writeauto
            if out ~= nil then
                size += out
            end
            if type == "number" then -- account the writeuint8 in writenumber
                size += 1
                if preciseFloats then -- account the writeuint8 in writeprecisefloatx
                    size += 1
                end
            end
        end
        local self = Writer.new(size)
        self.AutomaticPreciseFloats = preciseFloats
        self:writeuint8(IDENTIFIER_CONTEXT_LENGTH)
        self:writestringraw(IDENTIFIER_CONTEXT, IDENTIFIER_CONTEXT_LENGTH)
        for n = 1, values.n do
            self:writeauto(values[n])
        end
        return function(tostring: boolean?)
            Utility.ShrinkBuffer(self)
            return self:getbuffer(tostring)
        end
    end
end

return Writer