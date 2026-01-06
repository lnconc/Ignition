--!nonstrict
-- Class/Libs/free.lua

local xtypeof = require("../Utility/xtypeof")

local function free(item: any)
    if not item then return end
    if typeof(item) == "function" then
        item()
        return
    end
    local item_type = xtypeof(item)
    if item_type == "promise" then
        item:cancel()
    elseif item_type == "table" then
        if type(item.Destroy) == "function" then
            item:Destroy()
        elseif type(item.Disconnect) == "function" then
            item:Disconnect()
        else
            for key, value in item do
                free(value)
                item[key] = nil
                free(key)
            end
        end
    elseif item_type == "Instance" then
        item:Destroy()
    end
end

return free