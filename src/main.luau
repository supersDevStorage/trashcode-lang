-- 17:33 User Defined Functions & Closures

--[[ TODO List:

	and, or keywords for conditionals
	
]]

--[[ SOLVED List:

	Make a better way to parse arrays that have values with no keys (ex. { 5, 6, 4 })
		Solved by adding a separate array length counter that starts from 1, which is not affected by key: value pairings


]]

-- Get imports
local Imports = script.Parent.Imports

local parser = require(Imports.Frontend.parser)
local evaluate = require(Imports.Runtime.interpreter)
local valueConstructors = require(Imports.Runtime.valueConstructors)
local globalVariables = require(Imports.Runtime.globalVariables)



local function repl(code)
	print("trashcode v0.6")
	print("\n")
	
	local program = parser.produceAST(code, false)
	
	local environment = require("./Imports/Runtime/environment.luau")()

	for i, v in globalVariables do
		environment:declareVar(i, v, true)
	end
	
	print("Program output:")
	local interpretation = evaluate(program, environment, false)
end

local options = io.open("./sourceCode.lua", "r")
