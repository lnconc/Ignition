local Class = require(game.ReplicatedStorage.Ignition.Class)
local class, extends, property, nullable, union, abstract, final, reactive, mixin, FLAGS, once =
    Class.class, Class.extends, Class.property, Class.nullable, Class.union, Class.abstract, Class.final, Class.reactive, Class.mixin, Class.FLAGS, Class.once
if once() then return {} end

class "MyClass" (extends "MySuperClass" {
    public = {
        run = property { type = "function" }, 
        Message = "Hello!"
    },
    protected = {
    },
    private = {
        Secret = "Secret!   "
    },
})

return {}