--!strict
-- Class/Libs/mixin.lua

local Log = require("../../Log")
local Configuration = require("../Utility/Configuration")
local Registry = require("../Utility/Registry")
local is_property = require("../Utility/is_property")
local class = require("./class")

local VIRTUAL_FLAG = Configuration.PROPERTY_FLAGS.Virtual

local function mixin<M>(name: string)
    local mixin_interface = class(name)
    return function<I>(...: string | I): <P>(mixin_fields: P) -> I
        -- retrieve other interfaces for field dumping
        local components: { I } = {}
        for _, component in ipairs({ ... }) do
            local interface = component
            if type(interface) == "string" then
                interface = Registry.WaitForInterface(interface)
            end
            if interface.flags.ClassFinalized then
                Log.MIXIN_FINALIZED:throw(2, interface.name, name)
            end
            table.insert(components, interface)
        end
        return function<P>(mixin_fields: P): M
            local final_fields = { public = {}, private = {}, protected = {} }
            local closures, virtuals = {}, {}
            local function explicit_copy(dst: any, k, v, fromName: string)
                if is_property(v) then
                    local flags = v.flags
                    local isVirtual = flags[VIRTUAL_FLAG]
                    if dst[k] ~= nil then
                        local existingFlags = dst[k].flags
                        if not isVirtual or not existingFlags[VIRTUAL_FLAG] then
                            Log.MIXIN_COLLISION:throw(2, k, name, fromName)
                        end
                    end
                    
                    virtuals[k] = isVirtual
                end
                dst[k] = v
            end
            local function copy_fields_to(src: any, fromName: string)
                for specifierOrKey, fieldOrProperty in pairs(src) do
                    if not is_property(fieldOrProperty) then
                        for k, v in pairs(fieldOrProperty) do
                            explicit_copy(final_fields[specifierOrKey], k, v :: any, fromName)
                        end
                    else
                        explicit_copy(final_fields.public, specifierOrKey, fieldOrProperty, fromName)
                    end
                end
            end
            for _, component in ipairs(components :: { any }) do
                for key, impl in pairs(component.closures) do
                    if virtuals[key] then continue end
                    closures[key] = impl
                end
                copy_fields_to(component.properties, component.name)
            end
            copy_fields_to(mixin_fields, name)
            local interface = mixin_interface(final_fields)
            interface.closures = closures
            return interface
        end
    end
end

return mixin