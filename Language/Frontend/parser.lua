local Tokenizer = require("Frontend.lexer")
local TokenType = require("Frontend.tokenTypes")

local Parser = {}

local insert = table.insert
local remove = table.remove


local function findIndexFromValue(t, v)
	for i, val in t do
		if val == v then
			return i
		end
	end
	return nil -- Value doesn't exist in table
end


local function advance()
	return remove(Parser.tokens, 1)
end

local function at()
	return Parser.tokens[1]
end

local function expect(tokenType, errorMessage)
	local prev = remove(Parser.tokens, 1)
	if not prev or prev.kind ~= tokenType then
		local newErrorMessage = errorMessage or ""
		error(newErrorMessage .. " Expected " .. findIndexFromValue(TokenType, tokenType) .. " but got " .. findIndexFromValue(TokenType, prev.kind) .. " ({prev.value})")
	end
	return prev
end

--// Orders of Precedence \\-- (Higher is evaluated first)
-- PrimaryExpr
-- MemberExpr
-- FunctionCall
-- ExponentialExpr
-- MultiplicativeExpr
-- AdditiveExpr
-- FunctionExpr
-- ObjectExpr
-- ConditionalExpr
-- AssignmentExpr

function Parser:parseExpr()
	return parseAssignment()
end

function Parser:parseStmt()
	if at().kind == TokenType.Local then
		advance()
		return parseAssignment()
	else
		return self:parseExpr()
	end
end



function parseAssignment()
	local left = parseConditionalExpr()
	local nodeKind = "AssignmentStmt"

	if at().kind == TokenType.Local then
		nodeKind = "VarDeclaration"
	end

	if at().kind == TokenType.Equals then
		advance()
		local right = parseConditionalExpr()
		return {
			kind = nodeKind,
			assignees = {left},
			value = {right}
		}
	elseif at().kind == TokenType.Comma then
		local variables = {}
		while at().kind == TokenType.Comma do
			insert(variables, parseConditionalExpr())
		end

		expect(TokenType.Equals, "Expected equals following variable assignment.")
		
		local values = {}
		while at().kind == TokenType.Comma do
			insert(values, parseConditionalExpr())
		end

		if #variables ~= #values then error(("Cannot assign %s values to %s variables."):format(#values, #variables)) end

		return {
			kind = nodeKind,
			assignees = variables,
			value = values
		}
	end

	return left
end

function parseConditionalExpr()
	local left = parseObjectExpr()

	return left
end

function parseObjectExpr()
	local left = parseFunctionExpr()
	
	return left
end

function parseFunctionExpr()
	local left = parseAdditiveExpr()
	
	return left
end

function parseAdditiveExpr()
	local left = parseMultiplicativeExpr()
	
	while at().value == "+" or at().value == "-" or at().value == ".." do
		local operator = advance().value
		local right = parseMultiplicativeExpr()
		left = {
			kind = "BinaryExpr",
			left = left,
			right = right,
			operator = operator
		}
	end
	
	return left
end

function parseMultiplicativeExpr()
	local left = parseExponentialExpr()
	
	while at().value == "*" or at().value == "/" or at().value == "%" do
		local operator = advance().value
		local right = parseExponentialExpr()
		left = {
			kind = "BinaryExpr",
			left = left,
			right = right,
			operator = operator
		}
	end
	
	return left
end

function parseExponentialExpr()
	local left = parsePrimaryExpr()

	while at().value == "^" do
		local operator = advance().value
		local right = parsePrimaryExpr()
		left = {
			kind = "BinaryExpr",
			left = left,
			right = right,
			operator = operator
		}
	end

	return left
end

function parseCallExpr()
	local left = parseMemberExpr()
		
		return left
end

function parseMemberExpr()
	local left = parsePrimaryExpr()
	
	return left
end

function parsePrimaryExpr() -- returns an Expr
	local tk = at().kind

	if tk == TokenType.Identifier then
		return {
			kind = "Identifier",
			symbol = advance().value
		}
	elseif tk == TokenType.Number then
		return {
			kind = "NumericLiteral",
			value = tonumber(advance().value)
		}
	elseif tk == TokenType.String then
		return {
			kind = "StringLiteral",
			value = advance().value
		}
	elseif tk == TokenType.OpenParen then
		advance() -- remove opening parentheses
		local value = Parser:parseExpr()
		expect(TokenType.CloseParen, "Open parentheses never closed.") -- remove closing parentheses
		return value
	else
		print(inspect(Parser.tokens))
		error("Unexpected token found during parsing.")
	end
end





function Parser:produceAST(src)
	self.tokens = Tokenizer:Start(src)
	self.ast = {}

	while self.tokens[1].kind ~= TokenType.EndOfFile do
		insert(self.ast, Parser:parseStmt())
	end

	return {
		kind = "Program",
		body = self.ast
	}
end

return Parser