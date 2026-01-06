--!strict
-- Class/Libs/mixin.lua

local Types = require("../Types")
local Configuration = require("../Utility/Configuration")
local Registry = require("../Utility/Registry")
local is_property = require("../Utility/is_property")
local class = require("./class")

type FieldOptions = Types.FieldOptions
type Properties = Types.Properties
type Interface = Types.Interface

local VIRTUAL_FLAG = Configuration.PROPERTY_FLAGS.Virtual

local function mixin(name: string)
    local mixin_interface = class(name)
    return function(...: string)
        -- retrieve other interfaces for field dumping
        local components: { Interface } = {}
        for _, other_name in ipairs {...} do
            local component = Registry.GetInterface(other_name)
            if component.flags.ClassFinalized then
                error(`Cannot mixin finalized class '{other_name}' into '{name}'`, 2)
            end
            table.insert(components, component)
        end
        return function(mixin_fields: Properties)
            local final_fields = { public = {}, private = {}, protected = {} }
            local closures, virtuals = {}, {}
            local function explicit_copy(dst: any, k, v, fromName: string)
                if is_property(v) then
                    local flags = v.flags :: any
                    local isVirtual = if type(flags) == "table" then table.find(flags, VIRTUAL_FLAG) ~= nil else flags[VIRTUAL_FLAG]
                    
                    if dst[k] ~= nil then
                        local existingFlags = dst[k].flags :: any
                        local isExistingVirtual = if type(existingFlags) == "table" then table.find(existingFlags, VIRTUAL_FLAG) ~= nil else existingFlags[VIRTUAL_FLAG]
                        if not isVirtual or not isExistingVirtual then
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
                        for k, v in pairs(fieldOrProperty :: FieldOptions) do
                            explicit_copy(final_fields[specifierOrKey], k, v, fromName)
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
                copy_fields_to(component.properties_fields, component.name)
            end
            copy_fields_to(mixin_fields, name)
            mixin_interface(final_fields :: Properties)
            local interface = Registry.GetInterface(name)
            interface.closures = closures
        end
    end
end

return mixin