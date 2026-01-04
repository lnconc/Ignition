--!strict
-- MyClass.d.lua

local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Ignition = require(ReplicatedStorage.Ignition)
local Class = Ignition.Class

local class, property, final, func, FLAGS = Class.class, Class.property, Class.final, Class.func, Class.FLAGS

return final (class "MyClass" {
    public = {
        Hello = "World!",
        Readonly = property {
            exposure = "shared",
            flags = { FLAGS.Readonly },
            type = "string",
            value = "You can read me!"
        },
        GetSecret = func {
            exposure = "shared",
            flags = { },
            dummy = (nil :: any) :: () -> string,
        },
        RunAnonTest = func {
            exposure = "shared",
            flags = { },
            dummy = (nil :: any) :: () -> (),
        },
    },
    protected = {},
    private = {
        Secret = "I'm a secret!"
    },
})