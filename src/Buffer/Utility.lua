--!native

local LARGEST_FLOAT32_VAL = 3.4e+38
local INT8_RANGE, INT16_RANGE = NumberRange.new(-128, 127), NumberRange.new(-32768, 32767)
local MIN_UINT_RANGE = NumberRange.new(255, 65535)

local SIXTY_FOUR_BYTES, THIRTY_TWO_BYTES, SIXTEEN_BYTES, EIGHT_BYES = '64', '32', '16', '8'
local FLOAT_CONTEXT, INT_CONTEXT, UINT_CONTEXT = 'float', 'int', 'uint'
local MAX_BUFFER_SIZE = 2^30

local buff_copy = buffer.copy
local buff_create = buffer.create
local buff_len = buffer.len

local sign = math.sign
local max = math.max
local pow = math.pow
local log = math.log
local floor = math.floor

local Utility = {}
function Utility.AssumeNumberType(num: number): string
    local cast: string = if floor(num) ~= num then FLOAT_CONTEXT else (if num > 0 then INT_CONTEXT else UINT_CONTEXT)
    local type: string = if cast == FLOAT_CONTEXT then (if sign(num) == -1 then (if num > -LARGEST_FLOAT32_VAL then THIRTY_TWO_BYTES else SIXTY_FOUR_BYTES) else (if num < LARGEST_FLOAT32_VAL then THIRTY_TWO_BYTES else SIXTY_FOUR_BYTES))
        elseif cast == INT_CONTEXT then (if num >= INT8_RANGE.Min and num <= INT8_RANGE.Max then EIGHT_BYES elseif num >= INT16_RANGE.Min and num <= INT16_RANGE.Max then SIXTEEN_BYTES else THIRTY_TWO_BYTES)
        else (if num <= MIN_UINT_RANGE.Max then EIGHT_BYES elseif num <= MIN_UINT_RANGE.Max then SIXTEEN_BYTES else THIRTY_TWO_BYTES)
    return cast..type
end

function Utility.AssertForBufferSize(placement: number, cursor: number, buffSize: number): (number, number)
    local at = placement + cursor
    if at > buffSize then
        error(`buffer size overflow (exceeded {placement} bytes out of {buffSize} max bytes)`)
    end
    return at, placement
end

function Utility.ResizeBufferTo(buff: any, desiredSize: number)
    if desiredSize > MAX_BUFFER_SIZE then
        error(`cannot resize buffer to {desiredSize} bytes (max size: {MAX_BUFFER_SIZE} bytes)`)
    end
    buff._size = max(buff._size, desiredSize)
    if desiredSize < buff_len(buff._buffer) then
        return
    end

    local size = desiredSize
    local val = log(desiredSize, 2)
    local exp = floor(val)
    if exp ~= val then
        size = pow(exp+1, 2)
    end
    local old, new = buff._buffer, buff_create(size)
    buff_copy(new, 0, old, 0)
    buff._buffer = new
end

function Utility.ShrinkBuffer(buff: any)
    if buff._size == buff_len(buff._buffer) then
        return
    end
    local old, new = buff._buffer, buff_create(buff._size)
    buff_copy(new, 0, old, 0, buff._size)
    buff._buffer = new
end

function Utility.MergeBuffers(buffers: {any}): any
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

return Utility