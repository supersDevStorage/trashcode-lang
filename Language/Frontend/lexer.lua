local TokenTypes = require("Frontend.tokenTypes")

local sub = string.sub
local insert = table.insert

local Tokenizer = {}

Tokenizer.Keywords = {
	["local"] = TokenTypes.Local
}

function Tokenizer:handleCharacter(char)
	if tonumber(char) then
		local num = ""
		while tonumber(self:at()) do
			num = num .. self.src:sub(1, 1)
			self:shift()
		end

		return {
			kind = TokenTypes.Number,
			value = tonumber(num)
		}
	end

	if char == "+" or char == "-" or char == "*" or char == "/" or char == "^" or char == "%" then
		return {
			kind = TokenTypes.BinaryOperator,
			value = char
		}
	end

	if char == "." then
		if sub(self.src, 2, 2) == "." then
			self:shift()
			return {
				kind = TokenTypes.BinaryOperator,
				value = ".."
			}
		end
		return {
			kind = TokenTypes.Dot,
			value = "."
		}
	end

	if char == "=" then
		return {
			kind = TokenTypes.Equals,
			value = "="
		}
	end

	if char == "," then
		return {
			kind = TokenTypes.Comma,
			value = ","
		}
	end

	if char == '"' then
		self:shift() -- Move past the "
		local content = ""
		while #self.src > 0 and self:at() ~= '"' do
			content = content .. self:shift()
		end
		self:shift() -- Move past the closing "
		{
			kind = TokenTypes.String,
			value = content
		}
	end

	-- Reserved keywords
	if string.lower(char) ~= string.upper(char) then
		local identifier = ""
		while #self.src > 0 and string.lower(self:at()) ~= string.upper(self:at()) do
			identifier = identifier .. self:shift()
		end
		-- Check for reserved keywords
		local reserved = self.Keywords[identifier]
		if type(reserved) == "number" then
			return {
				kind = reserved,
				value = identifier
			}
		else
			return {
				kind = TokenTypes.Identifier,
				value = identifier
			}
		end
	end

	-- Error handling
	local start = (self.rawIndex - 5 and self.rawIndex > 5) or 1
	error('Unexpected character in source "' .. char .. '". (' .. sub(self.rawSrc, start, self.rawIndex) .. ")")
end

function Tokenizer:at()
	return sub(self.src, 1, 1)
end

function Tokenizer:shift()
	local prev = self:at()
	self.src = sub(self.src, 2, #self.src)
	return prev
end

function Tokenizer:Start(src)
	local i = 0
	-- These two are for debugging purposes. (printing the surrounding code with the error)
	self.rawSrc = src -- The unchanged source
	self.rawIndex = 1 -- The current position in rawSrc

	self.src = src -- (basically is always equal to string.sub(rawSrc, rawIndex, rawIndex))
	self.tokens = {}

	while #self.src > 0 do
		local char = self:at()
		if not (char == " " or char == "\t" or char == "\n") then
			insert(self.tokens, self:handleCharacter(char))
		end
		self:shift()
	end
	
	insert(self.tokens, {
		kind = TokenTypes.EndOfFile,
		value = "EOF"
	})

	return self.tokens
end

return Tokenizer