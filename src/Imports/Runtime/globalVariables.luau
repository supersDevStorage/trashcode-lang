local typeConstructors = require("./valueConstructors.luau")
local produceAST = require("../Frontend/parser.luau").produceAST

local module = {}

module.null = typeConstructors.makeNull()
module["true"] = typeConstructors.makeBoolean(true)
module["false"] = typeConstructors.makeBoolean(false)

--// NATIVE FUNCTIONS \\--

module["print"] = typeConstructors.makeNativeFunction(function(args, env)
	if #args ~= 1 then return module.null end
	
	local toPrint = args[1].value or args[1].properties or "function"
	print(toPrint)
	return module["true"]
end)

--// LIBRARIES \\--

local programStartTime = os.clock()

module["program"] = typeConstructors.makeObject({
	getRunTime = typeConstructors.makeNativeFunction(function(args, env)
		local stopTime = os.clock() - programStartTime
		
		local formattingStr = "%.3f"
		if args[1] and args[1].valType == "number" then
			formattingStr = "%." .. args[1].value .. "f"
		end
		
		return typeConstructors.makeNumber(string.format(formattingStr, stopTime * 1000))
	end),
	loadstring = typeConstructors.makeNativeFunction(function(args, env)
		if #args ~= 1 or args[1].valType ~= "string" then return module.null end
		
		local ast = produceAST(args[1].value).body
		
		return typeConstructors.makeFunction(ast)
	end)
})

return module
