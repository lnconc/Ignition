--!strict
-- Profiler.lua

type Stats = {
	Mean: number,
	Median: number,
	Mode: number,
	StDev: number,
	MAD: number,
	Min: number,
	Max: number
}

type LabelRecord = { label: string, start: number }
export type Controller = typeof(setmetatable({} :: { _activeLabels: { LabelRecord }, _results: { [string]: {number} } }, {} :: {
    profilebegin: (self: Controller, label: string) -> (),
    profileend: (self: Controller) -> (),
}))

local function getStats(data: {number}): Stats
	table.sort(data)
	local n = #data
	local sum = 0
	for _, v in data do sum += v end
	local mean = sum / n
	
	local counts = {}
	local maxFreq = 0
	local mode = data[1]
	
	for _, val in data do
		local rounded = math.round(val * 1e9) / 1e9
		counts[rounded] = ((counts[rounded] or 0) :: number) + 1
		if counts[rounded] > maxFreq then
			maxFreq = counts[rounded]
			mode = rounded
		end
	end
	
	local sqDiffSum = 0
	local absDiffSum = 0
	for _, v in data do
		sqDiffSum += (v - mean)^2
		absDiffSum += math.abs(v - mean)
	end

	return {
		Mean = mean,
		Median = (n % 2 == 0) and (data[n/2] + data[n/2+1])/2 or data[math.ceil(n/2)],
		Mode = mode,
		StDev = math.sqrt(sqDiffSum / n),
		MAD = absDiffSum / n,
		Min = data[1],
		Max = data[n]
	}
end

local Controller = {}
Controller.__index = Controller
function Controller.new(): Controller
    local self = {
		_activeLabels = {} :: { LabelRecord },
		_results = {} :: { [string]: {number} }
	}
    setmetatable(self, Controller)
	return self :: Controller
end

function Controller:profilebegin(label: string)
	if type(label) ~= "string" then error("expected a label for profilebegin()", 3) end
	table.insert(self._activeLabels, {
		label = label,
		start = os.clock()
	})
end

function Controller:profileend()
	local last = table.remove(self._activeLabels) :: LabelRecord
	if not last then
        warn("profileend() called without profilebegin()")
        return
    end
	
	local duration = os.clock() - last.start
	if not self._results[last.label] then
		self._results[last.label] = {}
	end
	table.insert(self._results[last.label], duration)
end

local ProfilerMetatable = {}
ProfilerMetatable.__index = ProfilerMetatable
ProfilerMetatable.__tostring = function()
	return "Profiler"
end

function ProfilerMetatable:run(label: string, batches: number, callback: (profile: Controller) -> ())
	if type(label) ~= "string" then error("expected a label for profilebegin()", 3) end
	local controller = Controller.new()
	print(string.format("\n\nProfiling [%s]...", label))
	local pauseEvery: number? = self._pauseEvery
	for x = 1, batches or 100 do
		if pauseEvery and x % pauseEvery == 0 then task.wait() end
		callback(controller)
	end
	if not next(controller._results) then
		error(`Profiler '{label}' did not return satisfiable results`, 2)
	end
	for blockLabel, times in controller._results do
		local stats = getStats(times)
		print(string.format("--- Block: %s ---", blockLabel))
		print(string.format("Mean: %.10f | StDev: %.10f | MAD: %.10f", stats.Mean, stats.StDev, stats.MAD))
		print(string.format("Median: %.10f | Min: %.10f | Max: %.10f", stats.Median, stats.Min, stats.Max))
	end
end

local Profiler = {}
function Profiler.new(pauseEvery: number?)
	return setmetatable({ _pauseEvery = pauseEvery or 10 }, ProfilerMetatable)
end

return Profiler