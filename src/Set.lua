--!native

local SetAPI = {}
function SetAPI:__tostring()
    return self:list()
end

function SetAPI:__add(with: Set) -- Union Operation
    for k in with._set do
        self._set[k] = true
    end
end

function SetAPI:__sub(from: Set) -- Subtract Operation
    for k in from._set do
        if self._set[k] ~= nil then
            self._set[k] = nil
        end
    end
end

function SetAPI:__div(from: Set) -- Intersect Operation
    for k in self._set do
        if from._set[k] == nil then
            self._set[k] = nil
        end
    end
end

function SetAPI:contains<T>(key: T): boolean
    return self._set[key] ~= nil
end

function SetAPI:list(): string
    local ls = {}
    for k in self._set do
        ls[#ls+1] = k
    end
    return table.concat(ls, ', ')
end

type Set = typeof(setmetatable({_set = {}}, {__index = SetAPI}))

return function(...)
    local set = {}
    for _, k in next, {...} do
        set[k] = true
    end

    local obj = setmetatable({_set = set}, {__index = SetAPI})
    return obj
end