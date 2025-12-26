--!strict
-- Class.lua

local abstract = require(script.Private.abstract)
local class = require(script.Private.class)
local extends = require(script.Private.extends)
local final = require(script.Private.final)
local import = require(script.Private.import)
local mixin = require(script.Private.mixin)
local new = require(script.Private.new)
local nullable = require(script.Private.nullable)
local once = require(script.Private.once)
local property = require(script.Private.property)
local reactive = require(script.Private.reactive)
local ref = require(script.Private.ref)
local super = require(script.Private.super)
local union = require(script.Private.union)
local Configuration = require(script.Utility.Configuration)

return {
    extends = extends,
    class = class,
    abstract = abstract,
    final = final,
    mixin = mixin,
    import = import,
    ref = ref,
    super = super,
    property = property,
    new = new,
    reactive = reactive,
    once = once,
    nullable = nullable,
    union = union,
    FLAGS = table.freeze(Configuration.PROPERTY_FLAGS)
}