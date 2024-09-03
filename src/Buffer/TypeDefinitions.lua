--- @class TypeDefinitions

export type table = typeof({})
--[=[
@type Datatype Vector3 | Vector3int16 | Vector2 | Vector2int16 | Rect | Region3 | Region3int16 | UDim | UDim2 | RaycastResult | Ray | DateTime
@within TypeDefinitions
]=]
export type Datatype = Vector3 | Vector3int16 |
    Vector2 | Vector2int16 |
    Region3 | Region3int16 | Rect |
    UDim | UDim2 |
    RaycastResult | Ray |
    DateTime

export type BufferWriter = {
    -- determinate
    writeuint8: (self: BufferWriter, input: number) -> (),
    writeuint16: (self: BufferWriter, input: number) -> (),
    writeuint32: (self: BufferWriter, input: number) -> (),
    
    writeint8: (self: BufferWriter, input: number) -> (),
    writeint16: (self: BufferWriter, input: number) -> (),
    writeint32: (self: BufferWriter, input: number) -> (),
    
    writefloat32: (self: BufferWriter, input: number) -> (),
    writeprecisefloat32: (self: BufferWriter, input: number) -> (),
    writefloat64: (self: BufferWriter, input: number) -> (),
    writeprecisefloat64: (self: BufferWriter, input: number) -> (),
    
    writestringraw: (self: BufferWriter, input: string, length: number?) -> (),
    writeboolean: (self: BufferWriter, input: boolean) -> (),

    -- indeterminate
    writestring: (self: BufferWriter, input: string) -> (),
    writenumber: (self: BufferWriter, input: number) -> (),

    writetable: (self: BufferWriter, input: table) -> (),
    writedatatype: (self: BufferWriter, input: Datatype) -> (),
    
    writeauto: (self: BufferReader, input: any) -> (),
    getbuffer: (self: BufferWriter, tostring: boolean?) -> (buffer),

    -- properties
    AutomaticPreciseFloats: boolean,
}

export type BufferReader = {
    -- determinate
    readuint8: (self: BufferReader) -> number,
    readuint16: (self: BufferReader) -> number,
    readuint32: (self: BufferReader) -> number,
    
    readint8: (self: BufferReader) -> number,
    readint16: (self: BufferReader) -> number,
    readint32: (self: BufferReader) -> number,
    
    readfloat32: (self: BufferReader) -> number,
    readprecisefloat32: (self: BufferReader) -> number,
    readfloat64: (self: BufferReader) -> number,
    readprecisefloat64: (self: BufferReader) -> number,

    readstringraw: (self: BufferReader, length: number) -> string,
    readboolean: (self: BufferReader) -> boolean,

    -- indeterminate
    readstring: (self: BufferReader) -> string,
    readnumber: (self: BufferReader) -> number,

    readtable: (self: BufferReader) -> table,
    readdatatype: (self: BufferReader) -> Datatype,

    readauto: (self: BufferReader) -> any,
}

return {}