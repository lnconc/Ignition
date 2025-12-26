--!strict
-- Class/Private/mixin.lua

local Types = require(script.Parent.Parent.Types)
local Registry = require(script.Parent.Parent.Utility.Registry)
local is_property = require(script.Parent.Parent.Utility.is_property)
local class = require(script.Parent.class)

type FieldsOption = Types.FieldsOption
type FieldOptions = Types.FieldOptions
type Interface = Types.Interface

local function mixin(name: string)
    local mixin_interface = class(name)
    return function(...: string)
        -- retrieve other interfaces for field dumping
        local components: { Interface } = {}
        for _, other_name in ipairs {...} do
            table.insert(components, Registry.GetInterface(other_name))
        end
        return function(mixin_fields: FieldsOption)
            local final_fields = { public = {}, private = {}, protected = {} }
            local closures = {}
            local function copy_fields_to(src: any)
                for specifierOrKey, fieldOrProperty in pairs(src) do
                    if not is_property(fieldOrProperty) then
                        for k, v in pairs(fieldOrProperty :: FieldOptions) do
                            final_fields[specifierOrKey][k] = v
                        end
                    else
                        final_fields.public[specifierOrKey] = fieldOrProperty
                    end
                end
            end
            for _, component in ipairs(components) do
                for key, id in pairs(component.closures) do
                    closures[key] = id
                end
                copy_fields_to(component.properties_fields)
            end
            copy_fields_to(mixin_fields)
            mixin_interface(final_fields)
            local interface = Registry.GetInterface(name)
            interface.closures = closures
        end
    end
end

return mixin