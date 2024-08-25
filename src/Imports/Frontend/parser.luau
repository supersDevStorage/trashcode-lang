local types, lexerReturns = require("./ast.luau"), require("./lexer.luau")
local TokenType = require("./TokenTypes.luau")
local tokenize, CreateToken = lexerReturns[1], lexerReturns[2]
local append = table.insert
local remove = table.remove

local tokens = {}



local function findIndexFromValue(t : {}, v)
	for i, val in t do
		if val == v then
			return i
		end
	end
	return nil -- Value doesn't exist in table
end



local function at()
	return tokens[1]
end

local function advance()
	return remove(tokens, 1)
end

local function expect(tokenType, errorMessage)
	local prev = remove(tokens, 1)
	if not prev or prev.tokenType ~= tokenType then
		local newErrorMessage = errorMessage or ""
		error(newErrorMessage .. ` Expected {findIndexFromValue(TokenType, tokenType)} but got {findIndexFromValue(TokenType, prev.tokenType)} ({prev.value})`)
	end
	return prev
end

local function notEOF()
	return (tokens[1].tokenType ~= TokenType.EndOfFile)
end

--// Orders of Precedence \\-- (Higher is more important)
-- PrimaryExpr
-- MemberExpr
-- FunctionCall
-- MultiplicativeExpr
-- AdditiveExpr
-- FunctionExpr
-- ObjectExpr
-- ConditionalExpr
-- AssignmentExpr



local function parsePrimaryExpr() -- returns an Expr
	local tk = at().tokenType

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
		local value = parseExpr()
		expect(TokenType.CloseParen, "Open parentheses never closed.") -- remove closing parentheses
		return value
	else
		print(tokens)
		error("Unexpected token found during parsing.")
	end
end

local function parseCallMemberExpr() : types.Expr
	local member = parseMemberExpr()
	
	if at().tokenType == TokenType.OpenParen then
		return parseCallExpr(member)
	end
	
	return member
end

function parseMemberExpr() : types.Expr
	local object = parsePrimaryExpr()
	
	while at().tokenType == TokenType.Dot or at().tokenType == TokenType.OpenBracket do
		local operator = advance()
		local property
		local isComputed
		
		-- non computed values (object.key)
		if operator.tokenType == TokenType.Dot then
			isComputed = false
			property = parsePrimaryExpr()
			
			if property.kind ~= "Identifier" then
				return error(`Cannot use dot operator without identifier.`)
			end
		else
			isComputed = true
			property = parseExpr()
			expect(TokenType.CloseBracket, `Missing closing bracket in member expression.`)
		end
		
		object = {
			kind = "MemberExpr",
			object = object,
			property = property,
			isComputed = isComputed
		} :: types.MemberExpr
	end
	
	return object
end

function parseCallExpr(caller : types.Expr) : types.Expr -- A subfunction of the parseCallMemberExpr function, which parses both function calls and member exprs using their respective functions
	local callExpr = {
		kind = "CallExpr",
		base = caller,
		args = parseFunctionArgs()
	} :: types.CallExpr

	if at() == TokenType.OpenParen then
		callExpr = parseCallExpr(callExpr)
	end

	return callExpr
end

function parseFunctionArgs() : {types.Expr} -- A subfunction of the parseCallExpr function, which parses function calls
	expect(TokenType.OpenParen, `Missing open parentheses from function call.`)

	local args
	if at().tokenType == TokenType.CloseParen then
		args = {}
	else
		args = parseFunctionArgsList()
	end

	expect(TokenType.CloseParen, `Missing closing parentheses from function call.`)
	
	return args
end

function parseFunctionArgsList() : {types.Expr} -- A subfunction of the parseFunctionArgs function, which parses the arguments in a function call
	local args = { parseAssignmentExpr() }
	
	while at().tokenType == TokenType.Comma and advance() do
		append(args, parseAssignmentExpr())
	end
	
	return args
end

local function parseMultiplicativeExpr() -- returns an Expr
	local left = parseCallMemberExpr()

	while at().value == "*" or at().value == "/" or at().value == "%" do
		local operator = advance().value
		local right = parseCallMemberExpr()
		left = {
			kind = "BinaryExpr",
			left = left,
			right = right,
			operator = operator
		}
	end

	return left
end


local function parseAdditiveExpr() -- returns an Expr
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

local function parseReturnExpr()
	advance() -- advance past return keyword
	
	return {
		kind = "ReturnExpr",
		
		value = parseExpr()
	} :: types.ReturnExpr
end

local function parseFunction()
	advance() -- advance past the function keyword
	
	if at().tokenType == TokenType.OpenParen then
		return parseFunctionExpr()
	elseif at().tokenType == TokenType.Identifier then
		return parseFunctionDeclaration()
	else
		print(tokens)
		return error(`Expected function name or open parenthesis in function expression.`)
	end
end

function parseFunctionExpr()
	local args = parseFunctionArgs()
	local parameters : {string} = {}

	for _, arg in args do
		if arg.kind ~= "Identifier" then
			return error(`Expected function parameter to have type of identifier.`)
		end

		append(parameters, (arg :: types.Identifier).symbol)
	end

	local body : {types.Stmt} = {}

	while at().tokenType ~= TokenType.EndOfFile and at().tokenType ~= TokenType.EndOfScope do
		append(body, parseStmt())
	end

	expect(TokenType.EndOfScope, `Expected function body to close in declaration.`)

	local functionExpr = {
		kind = "FunctionExpr",
		parameters = parameters,
		body = body
	} :: types.FunctionDeclaration

	return functionExpr
end

function parseFunctionDeclaration()
	local name = advance().value
	local args = parseFunctionArgs()
	local parameters : {string} = {}
	
	for _, arg in args do
		if arg.kind ~= "Identifier" then
			return error(`Expected function parameter to have type of identifier.`)
		end
		
		append(parameters, (arg :: types.Identifier).symbol)
	end
	
	local body : {types.Stmt} = {}
	
	while at().tokenType ~= TokenType.EndOfFile and at().tokenType ~= TokenType.EndOfScope do
		append(body, parseStmt())
	end
	
	expect(TokenType.EndOfScope, `Expected function body to close in declaration.`)
	
	local functionDeclaration = {
		kind = "FunctionDeclaration",
		name = name,
		parameters = parameters,
		body = body
	} :: types.FunctionDeclaration
	
	return functionDeclaration
end

local function parseVarDeclaration()
	local isConstant = (advance().tokenType == TokenType.Const)
	local identifier = expect(TokenType.Identifier, `Expected identifier during variable declaration.`).value

	if at().tokenType == TokenType.EndOfStmt then
		advance()
		if isConstant then return error(`Cannot initialize constant variable with no value. ({identifier})`) end
		return {
			kind = "VarDeclaration",
			constant = isConstant,
			identifier = identifier,
			value = nil
		}
	end

	expect(TokenType.Equals, `Expected equals token following identifier in variable initialization.`)

	local declaration = {
		kind = "VarDeclaration",
		identifier = identifier,
		constant = isConstant,
		value = parseExpr()
	} :: types.VarDeclaration

	return declaration
end

local function parseObjectExpr() : types.Expr
	if at().tokenType ~= TokenType.OpenBrace then return parseAdditiveExpr() end

	advance() -- advance past open brace
	local properties : { types.Property } = {}
	local numericKeyLength = 1 -- numerically keyed properties start at 1, not the length of the array as was previously the case

	while notEOF() and at().tokenType ~= TokenType.CloseBrace do
		local index = advance()
		
		if index.tokenType == TokenType.Identifier or index.tokenType == TokenType.Number then
			index = index.value
		else
			error(`Object literal key expected.`)
		end
		
		-- allows {key: value} to become {1: key} if a value is not provided
		if at().tokenType == TokenType.Comma then
			advance()
			append(properties, {
				kind = "Property",
				key = tostring(numericKeyLength),
				value = {
					kind = "Identifier",
					symbol = index
				} :: types.Identifier
			} :: types.Property)
			numericKeyLength += 1
			continue
		elseif at().tokenType == TokenType.CloseBrace then
			append(properties, {
				kind = "Property",
				key = tostring(numericKeyLength),
				value = {
					kind = "Identifier",
					symbol = index
				} :: types.Identifier
			})
			numericKeyLength += 1
			continue
		end

		expect(TokenType.ArrayEquals, `Missing colon following identifier in object.`)
		local value = parseExpr()

		append(properties, {
			kind = "Property",
			value = value,
			key = index
		})

		if at().tokenType ~= TokenType.CloseBrace then
			expect(TokenType.Comma, `Expected comma or closing brace after property.`)
		end
	end

	expect(TokenType.CloseBrace, `Object literal missing closing brace.`)

	return {
		kind = "ObjectLiteral",
		properties = properties
	} :: types.ObjectLiteral
end

function parseConditionalExpr()
	local left = parseObjectExpr()
	
	if at().tokenType == TokenType.ConditionalEquals then
		advance() -- advance past the == token
		local right = parseObjectExpr()
		return {
			kind = "ConditionalExpr",
			left = left,
			right = right,
			operator = "=="
		} :: types.ConditionalExpr
	elseif at().tokenType == TokenType.NotEquals then
		advance() -- advance past the ~= token
		local right = parseObjectExpr()
		return {
			kind = "ConditionalExpr",
			left = left,
			right = right,
			operator = "~="
		} :: types.ConditionalExpr
	elseif at().tokenType == TokenType.GreaterThanSign then
		advance() -- advance past the > token
		local right = parseObjectExpr()
		return {
			kind = "ConditionalExpr",
			left = left,
			right = right,
			operator = ">"
		} :: types.ConditionalExpr
	elseif at().tokenType == TokenType.LessThanSign then
		advance() -- advance past the < token
		local right = parseObjectExpr()
		return {
			kind = "ConditionalExpr",
			left = left,
			right = right,
			operator = "<"
		} :: types.ConditionalExpr
	end

	return left
end

function parseAssignmentExpr()
	local left = parseConditionalExpr()
	
	if at().tokenType == TokenType.CompoundEquals then
		local operator = advance().value
		
		return {
			kind = "AssignmentExpr",
			assignee = left,
			value = {
				kind = "BinaryExpr",
				left = left,
				right = parseAssignmentExpr(),
				operator = operator
			} :: types.BinaryExpr

		} :: types.AssignmentExpr
	end
	
	if at().tokenType == TokenType.Equals then
		advance() -- advance past the equals token
		local value = parseAssignmentExpr()
		
		return {
			kind = "AssignmentExpr",
			assignee = left,
			value = value
		} :: types.AssignmentExpr
	end

	return left
end

local function parseBodyFromToken(token)
	local body = {}
	expect(token, `Expected {findIndexFromValue(TokenType, token)} following loop condition.`)

	while at().tokenType ~= TokenType.EndOfFile and at().tokenType ~= TokenType.EndOfScope and at().tokenType ~= TokenType.Else do
		append(body, parseStmt())
	end
	return body
end

local function parseIfStatement()
	advance() -- Advance past the if keyword
	local condition = parseConditionalExpr()
	local body = parseBodyFromToken(TokenType.Then)
	local ifStatement = {
		kind = "IfStatement",
		condition = condition,
		body = body
	} :: types.IfStatement
	
	while at().tokenType == TokenType.Else do
		local condition
		local elseBody
		if at().tokenType == TokenType.If then
			condition = parseConditionalExpr()
			elseBody = parseBodyFromToken(TokenType.Then)
			
			ifStatement.elseBody = {
				{
					kind = "IfStatement",
					condition = condition,
					body = elseBody
				} :: types.IfStatement
			}
		else
			elseBody = parseBodyFromToken(TokenType.Else)
			
			ifStatement.elseBody = elseBody
		end
	end
	
	expect(TokenType.EndOfScope, `Expected scope to close after if statement.`)
	
	return ifStatement
end

local function parseWhileLoop()
	advance() -- Advance past the while keyword
	local condition = parseConditionalExpr()
	local body = parseBodyFromToken(TokenType.Do) 
	
	expect(TokenType.EndOfScope, `Expected scope to close after while loop.`)
	
	return {
		kind = "WhileLoop",
		condition = condition,
		body = body
	} :: types.WhileLoop
end

local function parseForLoop()
	advance() -- Advance past the for keyword
	local initializer = parseAssignmentExpr()
	local identifier = initializer.assignee
	local startIndex = initializer.value
	expect(TokenType.Comma, `Expected comma following for loop start index.`)
	local endIndex = parseExpr()
	local body = parseBodyFromToken(TokenType.Do) 
	
	expect(TokenType.EndOfScope, `Expected scope to close after for loop.`)

	return {
		kind = "ForLoop",
		identifier = identifier,
		startIndex = startIndex,
		endIndex = endIndex,
		body = body
	} :: types.ForLoop
end

function parseExpr() -- returns an Expr
	if at().tokenType == TokenType.Function then
		advance()
		return parseFunctionExpr()
	elseif at().tokenType == TokenType.Do then
		return parseBodyFromToken(TokenType.Do)
	elseif at().tokenType == TokenType.Then then
		return parseBodyFromToken(TokenType.Then)
	end
	return parseAssignmentExpr()
end



function parseStmt() -- returns a Stmt
	if at().tokenType == TokenType.Let then
		return parseVarDeclaration()
	elseif at().tokenType == TokenType.Const then
		return parseVarDeclaration()
	elseif at().tokenType == TokenType.Function then
		return parseFunction()
	elseif at().tokenType == TokenType.Return then
		return parseReturnExpr()
	elseif at().tokenType == TokenType.If then
		return parseIfStatement()
	elseif at().tokenType == TokenType.For then
		return parseForLoop()
	elseif at().tokenType == TokenType.While then
		return parseWhileLoop()
	elseif at().tokenType == TokenType.Break then
		advance()
		return {
			kind = "BreakStatement"
		} :: types.BreakStatement
	elseif at().tokenType == TokenType.Comment then
		return {
			kind = "CommentExpr",
			
			comment = advance().value
		} :: types.CommentExpr
	else
		return parseExpr()
	end
end

local Parser = {}
Parser = {
	
	produceAST = function(sourceCode: string, timeExecution : boolean): types.Program
		local program: types.Program = {
			kind = "Program",
			body = {},
			isAstInterface = false
		}
		if timeExecution then
			local startTime = os.clock()
			
			tokens = tokenize(sourceCode)
			
			local diffTime = os.clock() - startTime
			script.Parent.Parent.Parent.TimedExecutions.TokenizeTime.Value = diffTime * 1000
			-- Parse until End of File
			startTime = os.clock()
			
			if tokens[1].tokenType == TokenType.Comment then
				local comment = tokens[1]
				
				if comment.value == "!astInterface" then
					program.isAstInterface = true
				end
			end
			
			while notEOF() do
				append(program.body, parseStmt())
			end
			
			diffTime = os.clock() - startTime
			script.Parent.Parent.Parent.TimedExecutions.ParseTime.Value = diffTime * 1000
		else
			tokens = tokenize(sourceCode)

			if tokens[1].tokenType == TokenType.Comment then
				local comment = tokens[1]

				if comment.value == "!astInterface" then
					program.isAstInterface = true
				end
			end

			-- Parse until End of File
			while notEOF() do
				append(program.body, parseStmt())
			end
		end

		return program
	end,
}

return Parser
