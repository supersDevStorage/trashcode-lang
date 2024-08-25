local ast = require("../Frontend/ast.luau")

export type ValueType = "null" | "number" | "boolean" | "object" | "nativeFunction" | "string" | "function"

export type RuntimeVal = {
	kind: ValueType
}

export type NullVal = RuntimeVal & {
	["valType"]: ValueType,
	["value"]: string
}

export type NumberVal = RuntimeVal & {
	["valType"]: ValueType,
	["value"]: number
}

export type BooleanVal = RuntimeVal & {
	["valType"]: ValueType,
	["value"]: boolean
}

export type StringVal = RuntimeVal & {
	["valType"]: ValueType,
	["value"]: string
}

export type ObjectVal = RuntimeVal & {
	["valType"]: ValueType,
	["properties"]: {RuntimeVal}
}

export type FunctionCall = {
	args: {RuntimeVal},
	env: {} -- this is of type environment, whose class is found in the Runtime.environment module
}

export type NativeFunctionVal = RuntimeVal & {
	["valType"]: ValueType,
	["call"]: FunctionCall
}

export type FunctionVal = RuntimeVal & {
	["valType"]: ValueType,
	["name"]: string?,
	["parameters"]: {string},
	["body"]: {ast.Stmt},
	["declarationEnv"]: {} -- type of environment
}

return nil
