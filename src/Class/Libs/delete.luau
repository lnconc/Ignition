--!strict
-- Class/Libs/delete.lua

local env = require("../../Internal/env")
local Configuration = require("../Utility/Configuration")
local Registry = require("../Utility/Registry")
local StackSpider = require("../Utility/StackSpider") :: any
local anon = require("./anon") :: any
local free = require("./free")

local PRODUCTION_MODE_ENABLED = Configuration.PRODUCTION_MODE_ENABLED
local METAMETHODS = {
    "__add", "__sub", "__mul", "__div", "__mod", "__pow", "__unm",
    "__idiv", "__concat", "__len", "__eq", "__lt", "__le",
    "__call", "__tostring", "__iter", "__index", "__newindex"
}


local function delete(object: any)
    local environment = Registry.GetEnvironment(object)
    local super = environment.SuperClass
    if super and super.object then
        delete(super.object)
    end
    
    if (object :: any).Destroy then
        xpcall(function() (object :: any):Destroy() end, function(err) 
            warn(`an error occured while destroying an object via delete()\n{err}`)
        end)
    end
    
    environment.Deleting = true

    -- free up data
    local data = Registry.GetData(object)
    if PRODUCTION_MODE_ENABLED then
        for key, value in pairs(data) do
            free(value)
            data[key] = nil
        end
    else
        for _, ring in pairs(data) do
            if type(ring) ~= "table" then continue end
            for key, value in pairs(ring) do
                free(value)
                ring[key] = nil
            end
        end
    end

    -- delete metamethods (so that stack spider won't do anything)
    for _, method in METAMETHODS do
        environment.Metatable[method] = function()
            error(`attempt to perform operation "{method}" on a destroyed object`, 2)
        end
    end

    -- delete closures
    for _, closure in ipairs(environment.Closures) do
        StackSpider.delete(closure)
        anon.delete(closure)
        env.delete(closure)
    end
    table.clear(environment.Closures)

    Registry.PurgeObject(object)
end

return delete