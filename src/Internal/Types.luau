--!strict
-- State/Internal.luau

export type Function = <V>(...V) -> (...V)
export type FunctionEnvironment = { [string]: any }
export type Scriptable = LocalScript | Script | ModuleScript

return {}