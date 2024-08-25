local types = require("./valueTypes.luau")
local astTypes = require("../Frontend/ast.luau")

local function makeNumber(n) : types.NumberVal
	return {
		valType = "number",
		value = n or 0
	} :: types.NumberVal
end

local function makeString(s) : types.StringVal
	return {
		valType = "string",
		value = s or ""
	} :: types.StringVal
end

local function makeNull() : types.NullVal
	return {
		valType = "null",
		value = "null"
	} :: types.NullVal
end

local function makeBoolean(bool : boolean) : types.BooleanVal
	return {
		valType = "boolean",
		value = bool
	} :: types.BooleanVal
end

local function makeObject(properties : {}) : types.ObjectVal
	return {
		valType = "object",
		properties = properties
	} :: types.ObjectVal
end

local function makeNativeFunction(call : types.FunctionCall) : types.NativeFunctionVal
	return {
		valType = "nativeFunction",
		call = call
	} :: types.NativeFunctionVal
end

local function makeFunction(body: {astTypes.Stmt}, parameters : {string})
	return {
		["valType"] = "functionExpr",
		
		["parameters"] = parameters or {},
		["body"] = body
	}
end

return {
	makeNumber = makeNumber,
	makeString = makeString,
	makeNull = makeNull,
	makeBoolean = makeBoolean,
	makeObject = makeObject,
	makeNativeFunction = makeNativeFunction,
	makeFunction = makeFunction
}
