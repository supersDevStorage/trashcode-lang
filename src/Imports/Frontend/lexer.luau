local insert = table.insert
local remove = table.remove

local function shift(str)
	return remove(str, 1)
end

local TokenType = require("./TokenTypes.luau")

local Keywords = {
	["local"] = TokenType.Let,
	["const"] = TokenType.Const,
	["function"] = TokenType.Function,
	["end"] = TokenType.EndOfScope,
	["return"] = TokenType.Return,
	["for"] = TokenType.For,
	["while"] = TokenType.While,
	["if"] = TokenType.If,
	["then"] = TokenType.Then,
	["do"] = TokenType.Do,
	["else"] = TokenType.Else,
	["break"] = TokenType.Break,
}

local function CreateToken(val : string, typeOfToken : number)
	return { value = val, tokenType = typeOfToken }
end

local function isAlpha(str : string)
	return (string.upper(str) ~= string.lower(str))
end

local function isInt(str : string)
	return (true and tonumber(str)) or false
end

local function isSkippable(str : string)
	return (str == " " or str == "\n" or str == "\t" or str == "\r")
end

local function tokenize(sourceCode : string): {number}
	local tokens = {}
	local src = string.split(sourceCode, "")
	local arrayBraces = 0

	while #src > 0 do
		-- Begin parsing one character tokens
		
		if isSkippable(src[1]) then
			shift(src) continue
		elseif src[1] == "(" then
			insert(tokens, CreateToken(shift(src), TokenType.OpenParen))
			continue
		elseif src[1] == ")" then
			insert(tokens, CreateToken(shift(src), TokenType.CloseParen))
			continue
		elseif src[1] == "{" then
			arrayBraces += 1
			insert(tokens, CreateToken(shift(src), TokenType.OpenBrace))
			continue
		elseif src[1] == "}" then
			arrayBraces -= 1
			insert(tokens, CreateToken(shift(src), TokenType.CloseBrace))
			continue
		elseif src[1] == "[" then
			insert(tokens, CreateToken(shift(src), TokenType.OpenBracket))
			continue
		elseif src[1] == "]" then
			insert(tokens, CreateToken(shift(src), TokenType.CloseBracket))
			continue
		elseif src[1] == "-" then
			if src[2] == "-" then
				shift(src) -- advance past the comment dashes
				shift(src)
				local commentString = ""
				while src[1] ~= "\n" do
					commentString = commentString .. shift(src)
				end
				insert(tokens, CreateToken(commentString, TokenType.Comment))
				shift(src)
			elseif src[2] == "=" then
				insert(tokens, CreateToken(shift(src), TokenType.CompoundEquals))
				shift(src)
			else
				insert(tokens, CreateToken(shift(src), TokenType.BinaryOperator))
			end
			continue
				-- Handle binary operators
		elseif src[1] == "+" or src[1] == "*" or src[1] == "/" or src[1] == "%" then
			if src[2] == "=" then
				insert(tokens, CreateToken(shift(src), TokenType.CompoundEquals))
				shift(src)
			else
				insert(tokens, CreateToken(shift(src), TokenType.BinaryOperator))
			end
			continue
				-- Handle conditional and assignment tokens
		elseif src[1] == "=" then
			if arrayBraces > 0 then
				insert(tokens, CreateToken(shift(src), TokenType.ArrayEquals))
			elseif src[2] == "=" then
				shift(src)
				insert(tokens, CreateToken(shift(src), TokenType.ConditionalEquals))
			else
				insert(tokens, CreateToken(shift(src), TokenType.Equals))
			end
			continue
		elseif src[1] == "<" then
			insert(tokens, CreateToken(shift(src), TokenType.LessThanSign))
			continue
		elseif src[1] == ">" then
			insert(tokens, CreateToken(shift(src), TokenType.GreaterThanSign))
			continue
		elseif src[1] == "," then
			insert(tokens, CreateToken(shift(src), TokenType.Comma))
			continue
		elseif src[1] == "." then
			if src[2] == "." then
				shift(src)
				shift(src)
				insert(tokens, CreateToken("..", TokenType.StringConcat))
			else
				insert(tokens, CreateToken(shift(src), TokenType.Dot))
			end
			continue
		elseif src[1] == "~" then
			if src[2] == "=" then
				insert(tokens, CreateToken(shift(src), TokenType.NotEquals))
				shift(src)
			end
			continue
		else -- Handle numbers and identifiers
			if isInt(src[1]) then -- Handle number tokens
				local num = ""
				while #src > 0 and isInt(src[1]) do
					num = num .. shift(src)
				end
				insert(tokens, CreateToken(tonumber(num), TokenType.Number))
				continue
			elseif isAlpha(src[1]) then -- Handle identifier tokens (ex. Identifier = Value)
				local identifier = ""
				while #src > 0 and isAlpha(src[1]) do
					identifier = identifier .. shift(src)
				end
				-- Check for reserved keywords
				local reserved = Keywords[identifier]
				if typeof(reserved) == "number" then
					insert(tokens, CreateToken(identifier, Keywords[identifier]))
				else
					insert(tokens, CreateToken(identifier, TokenType.Identifier))
				end
				continue
			elseif src[1] == '"' then
				shift(src) -- Move past the "
				local content = ""
				while #src > 0 and src[1] ~= '"' do
					content = content .. shift(src)
				end
				shift(src) -- Move past the closing "
				insert(tokens, CreateToken(content, TokenType.String))
			else
				error("Unrecognized character in source: " .. src[1])
				return tokens
			end
		end
	end
	insert(tokens, CreateToken("EndOfFile", TokenType.EndOfFile))
	return tokens
end

return { tokenize, CreateToken, TokenType }
