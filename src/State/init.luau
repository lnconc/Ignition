
local Types = require("@self/Types")
local Value = require("@self/Value")
local Property = require("@self/Property")
local Observe = require("@self/Observe")
local peek = require("@self/peek")

type State = Types.State

local State = {
    Value = Value.new,
    Observe = Observe,
    Property = Property,
    peek = peek,
}

return table.freeze(State) :: State