--!strict
-- Class/Libs/mutual.lua
local friend = require("./friend")

local function mutual(objectA: any, objectB: any)
    friend(objectA, objectB)
    friend(objectB, objectA)
end

return mutual