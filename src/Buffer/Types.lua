
export type table = typeof({})
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
    
    writeufloat32: (self: BufferWriter, input: number) -> (),
    writeufloat64: (self: BufferWriter, input: number) -> (),
    
    writestringraw: (self: BufferWriter, input: string) -> (),

    -- indeterminate
    writestring: (self: BufferWriter, input: string) -> (),
    writenumber: (self: BufferWriter, input: number) -> (),

    writetable: (self: BufferWriter, input: table) -> (),
    writedatatype: (self: BufferWriter, input: Datatype) -> (),

    -- core
    getbuffer: (self: BufferWriter) -> (buffer)
}

export type BufferWriter = {
    
}

return {}