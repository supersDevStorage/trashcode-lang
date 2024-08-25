local valueTypes = require("./valueTypes.luau")
local globalVariables = require("./valueConstructors.luau")


local function newEnv(parentEnv)
	local module = {}

	module.parent = parentEnv
	module.variables = {}
	module.constants = {}

	function module:declareVar(varName : string, value : valueTypes.RuntimeVal, constant : boolean) : valueTypes.RuntimeVal
		if module.variables[varName] ~= nil then
			print(module.variables)
			error(`Cannot declare variable that has already been declared. ({varName})`)
		end
		
		if constant then
			module.constants[varName] = true
		end
		
		module.variables[varName] = value
		return value
	end

	function module:assignVar(varName : string, value : valueTypes.RuntimeVal) : valueTypes.RuntimeVal
		local env = self:resolve(varName)
		if env.constants[varName] then
			return error(`Cannot reassign a constant variable. ({varName})`)
		end
		
		env.variables[varName] = value
		
		return value
	end

	function module:lookupVar(varName : string) : valueTypes.RuntimeVal
		local env = self:resolve(varName)
		return env.variables[varName]
	end

	function module:resolve(varName : string)
		if module.variables[varName] ~= nil then return module end
		if not module.parent then return warn(`Cannot find variable {varName}`) end
		
		local currentEnv = module.parent
		while currentEnv do
			if currentEnv.variables[varName] ~= nil then return currentEnv end
			currentEnv = currentEnv.parent
		end
		
		return warn(`Cannot find variable {varName}`)
	end

	return module
end

return newEnv
