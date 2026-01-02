--!strict
-- Class/Libs/mixin.lua

local Types = require("../Types")
local Configuration = require("../Utility/Configuration")
local Registry = require("../Utility/Registry")
local is_property = require("../Utility/is_property")
local class = require("./class")

type PropertyField = Types.PropertyField
type PropertiesFields = Types.PropertiesFields
type Interface = Types.Interface
type Symbol<T> = Types.Symbol<T>

local VIRTUAL_FLAG = Configuration.PROPERTY_FLAGS.Virtual

local function mixin(name: string)
    local mixin_interface = class(name)
    return function(...: Interface)
        -- retrieve other interfaces for field dumping
        local components: { Interface } = { ... }
        for _, component in ipairs(components) do
            if component.flags.ClassFinalized then
                error(`Cannot mixin finalized class '{component.name}' into '{name}'`, 2)
            end
        end
        return function(mixin_fields: PropertiesFields)
            local final_fields = { public = {}, private = {}, protected = {} }
            local closures, virtuals = {}, {}
            local function explicit_copy(dst: any, k, v, fromName: string)
                if is_property(v) then
                    local flags = v.flags :: { [Symbol<string>]: boolean }
                    local isVirtual = flags[VIRTUAL_FLAG]
                    if dst[k] ~= nil then
                        local existingFlags = dst[k].flags :: { [Symbol<string>]: boolean }
                        if not isVirtual or not existingFlags[VIRTUAL_FLAG] then
                            error(`Member '{k}' in '{name}' is defined in multiple components, and at least one is non-virtual. (Check component: {fromName})`, 3)
                        end
                    end
                    
                    virtuals[k] = isVirtual
                end
                dst[k] = v
            end
            local function copy_fields_to(src: any, fromName: string)
                for specifierOrKey, fieldOrProperty in pairs(src) do
                    if not is_property(fieldOrProperty) then
                        for k, v in pairs(fieldOrProperty :: PropertyField) do
                            explicit_copy(final_fields[specifierOrKey], k, v :: any, fromName)
                        end
                    else
                        explicit_copy(final_fields.public, specifierOrKey, fieldOrProperty, fromName)
                    end
                end
            end
            for _, component in ipairs(components) do
                for key, impl in pairs(component.closures) do
                    if virtuals[key] then continue end
                    closures[key] = impl
                end
                copy_fields_to(component.properties, component.name)
            end
            copy_fields_to(mixin_fields, name)
            mixin_interface(final_fields :: PropertiesFields)
            local interface = Registry.GetInterface(name)
            interface.closures = closures
        end
    end
end

return mixin