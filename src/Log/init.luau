--!strict
-- Log.lua
local ErrorMessages = require("@self/ErrorMessages")

local PREFIX = "[Ignition]"
local LogContext = {}
LogContext.__index = LogContext
function LogContext:throw(level: number?, ...: any)
    local formatted = string.format(`{PREFIX} {self.message}` :: any, ...)
    error(formatted, (level or 2) + 1)
end

function LogContext:warn(...: any)
    warn(string.format(`{PREFIX} {self.message  }` :: any, ...))
end

function LogContext.new(message: string)
    return setmetatable({ message = message }, LogContext)
end

type LogContext = setmetatable<{ message: string }, {
    __index: {
        throw: (self: any, level: number?, ...any) -> (),
        warn: (self: any, ...any) -> (),
    }
}>
type ErrorMessagesKeys = keyof<ErrorMessages.ErrorMessages>
type function CompileLog(keys: type, context: type): type
    local nt = types.newtable({}, { index = types.string, readresult = context, writeresult = types.never })
    if keys:is("union") then
        for _, component in keys:components() do
            nt:setproperty(component, context)
        end
    end
    return nt
end

local Log = {}
for key, message in pairs(ErrorMessages :: { [string]: string }) do
    Log[key] = LogContext.new(message)
end

return table.freeze(Log) :: CompileLog<ErrorMessagesKeys, LogContext>