local valueConstructors = require("../valueConstructors.luau")
local astTypes, valueTypes = require(".../Frontend/ast.luau"), require("../valueTypes.luau")
local environmentConstructor = require("../environment.luau")
local globalVariables = require("../globalVariables.luau")



local append = table.insert

local function parseArray(t)
	local array = {}
	
	for i, v in t do
		if v.valType == "object" then
			array[i] = parseArray(v.properties)
		else
			array[i] = t[i].value
		end
	end
	
	return array
end


--[[

	STATEMENTS

]]

local evaluatedNodes = 0

function evalProgram(program : astTypes.Program, environment) : valueTypes.RuntimeVal
	local lastEvaluated = valueConstructors.makeNull()
	local evaluatedProgram = {}
	
	if program.body[1].kind == "CommentExpr" then
      local comment = program.body[1]

      if comment.comment == " !astInterface" then
        table.remove(program.body, 1)
        environment:declareVar("ast", valueConstructors.makeObject(program.body), true)
        environment:declareVar("evaluateAST", valueConstructors.makeNativeFunction(function(args, env)
          if #args ~= 1 or args[1].valType ~= "object" then return valueConstructors.makeNull() end
  
          evalProgram({
            ["kind"] = "Program",
  
            ["body"] = parseArray(args[1].properties),
            ["isAstInterface"] = false
          }, environment, timeExecution)
        end), true)
  
        environment:declareVar("compileAST", valueConstructors.makeNativeFunction(function(args, env)
          if #args ~= 1 or args[1].valType ~= "object" then return valueConstructors.makeNull() end
  
          return {
            ["valType"] = "functionExpr",
  
            ["parameters"] = {},
            ["body"] = parseArray(args[1].properties),
            ["declarationEnv"] = env
          } :: valueTypes.FunctionVal
        end), true)
      end
    end
  
    for _, statement in ipairs(program.body) do
      lastEvaluated = evaluate(statement, environment)
      append(evaluatedProgram, lastEvaluated)
    end
  end

	return evaluatedProgram
end

local function evalVarDeclaration(declaration : astTypes.VarDeclaration, env) : valueTypes.RuntimeVal
	local value = declaration.value
	if value then
		value = evaluate(value, env)
	else
		value = valueConstructors.makeNull()
	end

	return env:declareVar(declaration.identifier, value, declaration.constant)
end

local function evalFunctionDeclaration(declaration : astTypes.FunctionDeclaration, env) : valueTypes.RuntimeVal
	local functionVal : valueTypes.FunctionVal = {
		valType = "functionVal",
		name = declaration.name,
		parameters = declaration.parameters,
		declarationEnv = env,
		body = declaration.body
	}
	
	return env:declareVar(declaration.name, functionVal, false)
end

local function evalConditionalExpr(expr : astTypes.ConditionalExpr, env) : valueTypes.RuntimeVal
	local leftObj = evaluate(expr.left, env)
	local rightObj = evaluate(expr.right, env)
	local left = leftObj.value or leftObj.properties
	local right = rightObj.value or rightObj.properties
	
	if expr.operator == "==" then
		if left == right then
			return valueConstructors.makeBoolean(true)
		end
		return valueConstructors.makeBoolean(false)
	elseif expr.operator == "~=" then
		if left ~= right then
			return valueConstructors.makeBoolean(true)
		end
		return valueConstructors.makeBoolean(false)
	elseif expr.operator == ">" then
		if left > right then
			return valueConstructors.makeBoolean(true)
		end
		return valueConstructors.makeBoolean(false)
	elseif expr.operator == "<" then
		if left < right then
			return valueConstructors.makeBoolean(true)
		end
		return valueConstructors.makeBoolean(false)
	end
end

local function evalIfStatement(statement : astTypes.IfStatement, env) : valueTypes.RuntimeVal
	local condition = evalConditionalExpr(statement.condition, env)
	if condition.value == true then
		local scope = environmentConstructor(env)
		for _, stmt in ipairs(statement.body) do
			if stmt.kind == "BreakStatement" then return valueConstructors.makeNull() end
			evaluate(stmt, scope)
		end
		return valueConstructors.makeBoolean(true)
	elseif statement.elseBody then
		local scope = environmentConstructor(env)
		for _, stmt in ipairs(statement.elseBody) do
			if stmt.kind == "BreakStatement" then return valueConstructors.makeNull() end
			evaluate(stmt, scope)
		end
	end
	return valueConstructors.makeBoolean(false)
end

local function evalWhileLoop(loop : astTypes.WhileLoop, env) : valueTypes.RuntimeVal
	local scope = environmentConstructor(env)
	
	while evalConditionalExpr(loop.condition, env).value == true do
		for _, stmt in ipairs(loop.body) do
			if stmt.kind == "BreakStatement" then return valueConstructors.makeNull() end
			evaluate(stmt, scope)
		end
		
		for i, v in scope.variables do
			if not scope.constants[i] then
				scope.variables[i] = nil
			end
		end
	end
	
	return valueConstructors.makeNull()
end

local function evalForLoop(loop : astTypes.ForLoop, env) : valueTypes.RuntimeVal
	local scope = environmentConstructor(env)
	local endIndex = evaluate(loop.endIndex, env).value
	local identifier = loop.identifier.symbol
	scope:declareVar(identifier, evaluate(loop.startIndex, env), false)
	
	while scope:lookupVar(identifier).value <= endIndex do
		for _, stmt in ipairs(loop.body) do
			if stmt.kind == "BreakStatement" then return valueConstructors.makeNull() end
			evaluate(stmt, scope)
		end
		
		for i, v in scope.variables do
			if i ~= identifier and not scope.constants[i] then
				scope.variables[i] = nil
			end
		end
		scope:assignVar(identifier, valueConstructors.makeNumber(scope:lookupVar(identifier).value + 1))
	end

	return valueConstructors.makeNull()
end






--[[

	EXPRESSIONS

]]

local function evalNumericBinaryExpr(left : valueTypes.NumberVal, right : valueTypes.NumberVal, operator : string) : valueTypes.NumberVal
	local result = 0

	if operator == "+" then
		result = left.value + right.value
	elseif operator == "-" then
		result = left.value - right.value
	elseif operator == "*" then
		result = left.value * right.value
	elseif operator == "/" then
		result = left.value / right.value
	elseif operator == "%" then
		result = left.value % right.value
	end

	return valueConstructors.makeNumber(result)
end

local function evalConcatBinaryExpr(left : valueTypes.RuntimeVal, right : valueTypes.RuntimeVal, operator : string) : valueTypes.RuntimeVal
	local canConcat = (tostring(left) and tostring(right))
	
	if canConcat then
		return {
			valType = "string",
			value = tostring(left) .. tostring(right)
		} :: valueTypes.StringVal
	else
		return valueConstructors.makeNull()
	end
end

local function evalBinaryExpr(binop : astTypes.BinaryExpr, environment) : valueTypes.RuntimeVal
	local left = evaluate(binop.left, environment)
	local right = evaluate(binop.right, environment)
	if left.valType == "number" and right.valType == "number" then
		return evalNumericBinaryExpr(left :: valueTypes.NumberVal, right :: valueTypes.NumberVal, binop.operator)
	elseif binop.operator == ".." then
		local leftSide = left.value or environment:lookupVar(left.symbol)
		local rightSide = right.value or environment:lookupVar(right.symbol)
		return evalConcatBinaryExpr(leftSide, rightSide)
	end

	-- One or both sides are null
	return valueConstructors.makeNull()
end

local function evalFunctionExpr(declaration : astTypes.FunctionExpr, env) : valueTypes.RuntimeVal
	local functionVal : valueTypes.FunctionExpr = {
		valType = "functionExpr",
		parameters = declaration.parameters,
		body = declaration.body
	}

	return functionVal
end

local function evalMemberExpr(expr : astTypes.MemberExpr, env) : valueTypes.RuntimeVal
	local object = env:lookupVar(expr.object.symbol)
	if object.valType == "object" then
		local prop = object.properties[expr.property.symbol]
		if prop then
			return prop
		else
			return error(`{expr.object.symbol} object has no property {expr.property.symbol}`)
		end
	else
		return error(`{expr.object.symbol} is not an object`)
	end
end

local function evalIdentifier(identifier : astTypes.Identifier, environment) : valueTypes.RuntimeVal
	local value = environment:lookupVar(identifier.symbol)
	return value
end

local function evalObjectExpr(object : astTypes.ObjectLiteral, env) : valueTypes.RuntimeVal
	local objectValue = {
		valType = "object",
		properties = {}
	} :: valueTypes.ObjectVal
	for _, prop in object.properties do
		local runtimeVal
		if not prop.value and not prop.properties then
			runtimeVal = env:lookupVar(prop.key)
		else
			runtimeVal = evaluate(prop.value, env)
		end
		
		objectValue.properties[prop.key] = runtimeVal
	end
	
	return objectValue
end

local function evalCallExpr(call : astTypes.CallExpr, env) : valueTypes.RuntimeVal
	local args = {}
	for _, v in ipairs(call.args) do
		append(args, evaluate(v, env))
	end
	
	local func = evaluate(call.base, env)
	
	if func.valType == "nativeFunction" then
		local result = (func :: valueTypes.NativeFunctionVal).call(args, env)
		
		return result
	elseif func.valType == "functionVal" or func.valType == "functionExpr" then
		local fn = func :: valueTypes.FunctionVal
		local scope = environmentConstructor(env)
		fn.declarationEnv = scope
		
		-- Create variables for parameters list
		if #args ~= #fn.parameters then -- check if the amount of args passed is in line with the amount of args the function has
			return error(`Cannot call a function with more or less arguments than it is declared as.`)
		end
		
		for i, varName in fn.parameters do
			scope:declareVar(varName, args[i], false)
		end
		
		local result : valueTypes.RuntimeVal = valueConstructors.makeNull()
		
		for i = 1, #fn.body do
			local stmt = fn.body[i]
			if stmt.kind == "ReturnExpr" then
				return evaluate(stmt.value, scope)
			else
				result = evaluate(stmt, scope)
			end
		end
		
		return result
	end
	return error(`Cannot call a non-function value.`)
end

local function evalAssignmentExpr(assignment : astTypes.AssignmentExpr, env)
	if assignment.assignee.kind ~= "Identifier" then
		print(assignment.assignee)
		return error(`Invalid assignee in variable assignment.`)
	end

	local varName = (assignment.assignee :: astTypes.Identifier).symbol
	return env:assignVar(varName, evaluate(assignment.value, env))
end




function evaluate(astNode : astTypes.Stmt, environment, timeExecution : boolean) : valueTypes.RuntimeVal
	evaluatedNodes = evaluatedNodes + 1
	if astNode.kind == "NumericLiteral" then
		return valueConstructors.makeNumber((astNode :: astTypes.NumericLiteral).value)
	elseif astNode.kind == "StringLiteral" then
		return valueConstructors.makeString((astNode :: astTypes.StringLiteral).value)
	elseif astNode.kind == "Identifier" then
		return evalIdentifier(astNode :: astTypes.Identifier, environment)
	elseif astNode.kind == "ObjectLiteral" then
		return evalObjectExpr(astNode :: astTypes.ObjectLiteral, environment)
	elseif astNode.kind == "CallExpr" then
		return evalCallExpr(astNode :: astTypes.CallExpr, environment)
	elseif astNode.kind == "BinaryExpr" then
		return evalBinaryExpr(astNode :: astTypes.BinaryExpr, environment)
	elseif astNode.kind == "FunctionExpr" then
		return evalFunctionExpr(astNode :: astTypes.FunctionExpr, environment)
	elseif astNode.kind == "MemberExpr" then
		return evalMemberExpr(astNode :: astTypes.MemberExpr, environment)
	elseif astNode.kind == "Program" then
		return evalProgram(astNode :: astTypes.Program, environment, timeExecution)
	elseif astNode.kind == "VarDeclaration" then
		return evalVarDeclaration(astNode :: astTypes.VarDeclaration, environment)
	elseif astNode.kind == "FunctionDeclaration" then
		return evalFunctionDeclaration(astNode :: astTypes.FunctionDeclaration, environment)
	elseif astNode.kind == "IfStatement" then
		return evalIfStatement(astNode :: astTypes.IfStatement, environment)
	elseif astNode.kind == "WhileLoop" then
		return evalWhileLoop(astNode :: astTypes.WhileLoop, environment)
	elseif astNode.kind == "ForLoop" then
		return evalForLoop(astNode :: astTypes.ForLoop, environment)
	elseif astNode.kind == "AssignmentExpr" then
		return evalAssignmentExpr(astNode :: astTypes.AssignmentExpr, environment)
	elseif astNode.kind == "CommentExpr" then
		return 
	elseif astNode.kind == "BreakStatement" then
			error(`Cannot break outside of a loop or if statement.`)
	else -- Error
		print(astNode)
		error("This AST Node has not been setup for interpretation correctly.")
	end
end

return evaluate
