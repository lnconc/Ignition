--!strict
-- Class/Libs/friend.lua
local Log = require("../../Log")
local Configuration = require("../Utility/Configuration")
local Registry = require("../Utility/Registry")

local PRODUCTION_MODE_ENABLED = Configuration.PRODUCTION_MODE_ENABLED

local function friend(subject: any, guest: any, methodName: string?)
    if PRODUCTION_MODE_ENABLED then return end -- technically we can access everything once we're in production since encapsulate is stripped bare  
    if not Registry.HasObject(subject) then
        Log.FRIEND_TARGET_INVALID:throw(2)
    end
    local subjectEnv = Registry.GetEnvironment(subject)
    local guestType = type(guest)
    local isGuestClass = guestType == "userdata" and Registry.HasObject(guest)

    if methodName ~= nil and isGuestClass then
        local guestData = Registry.GetData(guest)
        local targetWrapper = (guestData.private[methodName] or guestData.protected[methodName] or guestData.public[methodName])
        
        if type(targetWrapper) == "function" then
            subjectEnv.Context.Friends[tostring(targetWrapper)] = true
            return
        end
        Log.FRIEND_METHOD_NOT_FOUND:throw(2, methodName)
    end

    if guestType == "function" then
        subjectEnv.Context.Friends[tostring(guest)] = true
    elseif isGuestClass then
        local guestEnv = Registry.GetEnvironment(guest)
        for context, _ in pairs(guestEnv.Context.Includes) do
            subjectEnv.Context.Friends[context] = true
        end
    elseif guestType == "table" then
        for _, member in pairs(guest) do
            if type(member) == "function" then
                subjectEnv.Context.Friends[tostring(member)] = true
            end
        end
    else
        Log.FRIEND_GUEST_INVALID:throw(2, typeof(guest))
    end
end

return friend