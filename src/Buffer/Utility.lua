--!native

local Symbol = require(script.Parent.Parent.Symbol)
local Datatypes = require(script.Parent.Datatypes)

local LARGEST_FLOAT32_VAL = 3.4e+38
local INT8_RANGE, INT16_RANGE = NumberRange.new(-128, 127), NumberRange.new(-32768, 32767)
local MIN_UINT_RANGE = NumberRange.new(255, 65535)

local SIXTY_FOUR_BYTES, THIRTY_TWO_BYTES, SIXTEEN_BYTES, EIGHT_BYES = 64, 32, 16, 8
local PRECISE_FLOAT_CONTEXT, FLOAT_CONTEXT, INT_CONTEXT, UINT_CONTEXT = 'precisefloat', 'float', 'int', 'uint'
local MAX_BUFFER_SIZE = 2^30

local buff_copy = buffer.copy
local buff_create = buffer.create
local buff_len = buffer.len

local sign = math.sign
local max = math.max
local log = math.log
local floor = math.floor

local function round(num: number, places: number?): number
	local decimalPivot = 10^(places or 1)
	return floor(num * decimalPivot + 0.5) / decimalPivot
end

local function getSizeOfTable(tbl: {any}): number
    local len = 2 -- account for the writeuint16 inside writetable
    for key, value in tbl do
        len += 1
        if type(key) == "table" then
            len += getSizeOfTable(key)
        end
        if type(value) == "table" then
            len += getSizeOfTable(value)
        end
    end
    return len
end

--- @class BufferUtility
--- Utility functions and helpers.
local Utility = {}

--[=[
@within BufferUtility
@private
@function Round
@param num number
@param places number
@return number
]=]
Utility.Round = round

--[=[
@within BufferUtility
@prop BufferFromDumpIdentifier Symbol
]=]
Utility.BufferFromDumpIdentifier = Symbol("DumpedBuffer")

--[=[
@within BufferUtility
Assume whether the provided number is an unsigned interger, interger, or float.
]=]
function Utility.AssumeNumberType(num: number, preciseFloats: boolean?): (string, number)
    local cast: string = if floor(num) ~= num then (if preciseFloats then PRECISE_FLOAT_CONTEXT else FLOAT_CONTEXT) else (if num > 0 then INT_CONTEXT else UINT_CONTEXT)
    local type: string = if cast == FLOAT_CONTEXT or cast == PRECISE_FLOAT_CONTEXT then (if sign(num) == -1 then (if num > -LARGEST_FLOAT32_VAL then THIRTY_TWO_BYTES else SIXTY_FOUR_BYTES) else (if num < LARGEST_FLOAT32_VAL then THIRTY_TWO_BYTES else SIXTY_FOUR_BYTES))
        elseif cast == INT_CONTEXT then (if num >= INT8_RANGE.Min and num <= INT8_RANGE.Max then EIGHT_BYES elseif num >= INT16_RANGE.Min and num <= INT16_RANGE.Max then SIXTEEN_BYTES else THIRTY_TWO_BYTES)
        else (if num <= MIN_UINT_RANGE.Max then EIGHT_BYES elseif num <= MIN_UINT_RANGE.Max then SIXTEEN_BYTES else THIRTY_TWO_BYTES)
    return cast..type, type
end

--[=[
@within BufferUtility
@param buff buffer
@param desiredSize
@private
Resizes the target buffer to allocate more space.
]=]
function Utility.ResizeBufferTo(buff: any, desiredSize: number)
    if desiredSize > MAX_BUFFER_SIZE then
        error(`cannot resize buffer to {desiredSize} bytes (max size: {MAX_BUFFER_SIZE} bytes)`, 3)
    end
    buff._size = max(buff._size, desiredSize)
    if desiredSize < buff_len(buff._buffer) then
        return
    end
    local size = desiredSize
    local val = log(desiredSize, 2)
    if floor(val) ~= val then
        size = 2^(floor(val)+1)
    end
    local old, new = buff._buffer, buff_create(size)
    buff_copy(new, 0, old, 0)
    buff._buffer = new
end

--[=[
@within BufferUtility
@param buff buffer
@private
Truncates the buffer to alleviate redundant or unoccupied space.
]=]
function Utility.ShrinkBuffer(buff: any)
    if buff._size == buff_len(buff._buffer) then
        return
    end
    local old, new = buff._buffer, buff_create(buff._size)
    buff_copy(new, 0, old, 0, buff._size)
    buff._buffer = new
end

--[=[
@within BufferUtility
@param buffers {buffer}
Merges multiple buffers into one, single buffer.
Mainly serves as an external utility as it's not used internally.
]=]
function Utility.MergeBuffers(buffers: {buffer}): {buffer}
    local mergeCount = #buffers
    if mergeCount == 0 then
        return nil
    elseif mergeCount == 1 then
        return buffers[1]
    end

    local totalSize = 0
    for k = 1, mergeCount do
        totalSize += buff_len(buffers[k])
    end
    local mergedBuffer = buff_create(totalSize)
    local bufferCursor = 0
    for k = 1, mergeCount do
        local currentBuffer = buffers[k]
        buff_copy(mergedBuffer, bufferCursor, currentBuffer)
        bufferCursor += buff_len(currentBuffer)
    end
    return mergedBuffer
end

--[=[
@within BufferUtility
@param datatype any
@return number
Retrieve the bytesize of the target datatype.
]=]
function Utility.GetByteSize(datatype: any): (number, number?)
    local type = type(datatype)
    if type == "string" then
        return #datatype, 2
    elseif type == "number" then
        local cast, size = Utility.AssumeNumberType(datatype)
        return size / 8, #cast
    elseif type == "boolean" then
        return 1
    elseif type == "table" then
        return getSizeOfTable(datatype)
    else
        type = typeof(datatype)
        return assert(Datatypes.ReadWrite[type], `datatype "{type}" is unsupported`).ByteSize
    end
end

return Utility