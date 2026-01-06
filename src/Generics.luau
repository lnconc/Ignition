--!strict
-- Generics.lua

type function filter_nil(t: type): type
    if not t:is("union") then
        return if t == types.singleton(nil) then types.never else t
    end

    local components = {}
    for _, comp in t:components() do
        if comp ~= types.singleton(nil) then
            table.insert(components, comp)
        end
    end

    if #components == 0 then return types.never
	elseif #components == 1 then return components[1]
end
    return types.unionof(unpack(components))
end

export type function Omit(T: type, K: type)
    local properties = {}
    local function collect_properties(ty: type)
        if ty:is("table") then
            for k, v in ty:properties() do
                properties[k] = v
            end
        elseif ty:is("intersection") then
            for _, component in ty:components() do
                collect_properties(component)
            end
        else
            error("Omit: T must be a table or an intersection of tables")
        end
    end
    collect_properties(T)

    local result = types.newtable()
    for k, v in properties do
        if not K:readproperty(k) then
            result:setreadproperty(k, v.read)
            result:setwriteproperty(k, v.write)
        end
    end
    return result
end

export type function Pick(T: type, K: type)
    assert(T:is("table"), "Pick: T must be a table")
    local result = types.newtable()
    
    for k, v in T:properties() do
        if K:readproperty(k) then
            result:setreadproperty(k, v.read)
            result:setwriteproperty(k, v.write)
        end
    end
    return result
end

export type function Partial(T: type)
    assert(T:is("table"), "Partial: T must be a table")
    local result = types.newtable()
    local nil_type = types.singleton(nil)

    for k, v in T:properties() do
        result:setreadproperty(k, types.unionof(v.read :: type, nil_type))
        result:setwriteproperty(k, types.unionof(v.write :: type, nil_type))
    end
    return result
end

export type function Required(T: type)
    assert(T:is("table"), "Required: T must be a table")
    local result = types.newtable()

    for k, v in T:properties() do
        result:setreadproperty(k, filter_nil(v.read))
        result:setwriteproperty(k, filter_nil(v.write))
    end
    return result
end

export type function Shallow(T: type)
	assert(T:is("table"), "Shallow: T must be a table type")
	local result = types.newtable({})
	for k, v in T:properties() do
		local read_type = v.read or types.never
		local write_type = v.write or types.never

		if read_type:is("table") or write_type:is("table") then
			result:setreadproperty(k, types.never)
			result:setwriteproperty(k, types.never)
		else
			result:setreadproperty(k, read_type)
			result:setwriteproperty(k, write_type)
		end
	end

	return result
end

export type function Readonly(T: type)
    assert(T:is("table"), "Readonly: T must be a table")
    local result = types.newtable()
    for k, v in T:properties() do
        result:setreadproperty(k, v.read)
    end
    return result
end

export type function Exclude(T: type, U: type)
	assert(T:is("union"), "Exclude: T must be a union type")
	local components = {}
	for _, comp in T:components() do
		if comp ~= U then
			table.insert(components, comp)
		end
	end

	if #components == 0 then
		return types.never
	elseif #components == 1 then
		return components[1]
	else
		return types.unionof(unpack(components))
	end
end

export type function NonNullable(T: type)
	assert(T:is("union"), "NonNullable: T must be a union type")
	local null = types.singleton(nil)
	local components = {}
	for _, comp in T:components() do
		if comp ~= null then
			table.insert(components, comp)
		end
	end

	if #components == 0 then
		return types.never
	elseif #components == 1 then
		return components[1]
	else
		return types.unionof(unpack(components))
	end
end

export type function Record(K: type, V: type)
    local result = types.newtable()
    if K:is("union") then
        for _, key in K:components() do
            result:setproperty(key, V)
        end
    else
        result:setproperty(K, V)
    end
    return result
end

export type function Parameters(T: type)
	assert(T:is("function"), "Parameters: T must be a function type")
	local params = T:parameters()
	local param_table = types.newtable({})
	if params.head then
		for i, param_type in params.head do
			local key = types.singleton(tostring(i)) -- Keys are 1, 2, 3...
			param_table:setproperty(key, param_type)
		end
	end

	if params.tail then
		param_table:setindexer(types.number, params.tail, params.tail)
	end

	return param_table
end

export type function ReturnType(T: type)
    assert(T:is("function"), "ReturnType: T must be a function")
    local returns = T:returns()
    if returns.head and #returns.head > 0 then
        return returns.head[1]
    end
    return types.singleton(nil)
end

export type function MapProperties(T: type, V: type)
	assert(T:is("table"), "MapProperties: T must be a table type")
	local result = types.newtable({})
	for k, _ in T:properties() do
		result:setreadproperty(k, V)
		result:setwriteproperty(k, V)
	end

	return result
end

export type function Decorator(T: type, R: type)
	assert(T:is("function"), "Decorator: T must be a function type")
	local params = T:parameters()
	local new_returns: { head: {type}?, tail: type? } = { 
		head = { R }, 
		tail = types.never                 
	}

	return types.newfunction(params, new_returns)
end

export type function Asyncify(T: type)
	assert(T:is("function"), "Asyncify: T must be a function type")
	local params = T:parameters()
	local returns = T:returns()
	local original_return = if returns.head and #returns.head > 0 
		then returns.head[1] 
		else types.singleton(nil) 

	local future_return = types.newtable({})
	future_return:setindexer(original_return, original_return, original_return)

	local new_returns: { head: {type}?, tail: type? } = { 
		head = { future_return }, 
		tail = nil                 
	}

	return types.newfunction(params, new_returns)
end

export type function Memoize(T: type)
	assert(T:is("function"), "Memoize: T must be a function type")
	return T 
end

export type function Curry(T: type)
    if not T:is("function") then
        error("Curry: T must be a function type", 2)
    end

    local params = T:parameters()
    local returns = T:returns()
    if not params.head or #params.head ~= 2 then
        error("Curry: T must take exactly two fixed arguments in its head", 2)
    end

    local type_A = params.head[1]
    local type_B = params.head[2]
    local return_type = if returns.head and #returns.head > 0 
        then returns.head[1] 
        else types.any
    local inner_func_type = types.newfunction(
        { head = { type_B } }, 
        { head = { return_type } }
    )
    return types.newfunction(
        { head = { type_A } }, 
        { head = { inner_func_type } }
    )
end

return {}