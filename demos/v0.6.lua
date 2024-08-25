-- !astInterface

-- This is a quick demo script that covers all the features added in TrashCode v0.6.

local testAst = {
	1 = {
		kind = "CallExpr",
		base = {
			kind = "Identifier",
			symbol = "print"
		},
		args = {
			1 = {
				kind = "StringLiteral",
				value = "hi"
			}
		}
	}
}

local func = compileAST(testAst)
func()

evaluateAST(testAst)

local message = "hello " .. "world!" .. " loadstring works! (kind of?)"
local funcTwo = program.loadstring("print(message)")
funcTwo()
