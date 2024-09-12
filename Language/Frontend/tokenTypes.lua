local TokenTypes = {
	-- Literals
	"Number",
	"String",
	"Identifier",

	-- Grouping symbols
	"BinaryOperator",
	"OpenParen", "CloseParen", -- "(" and ")" respectively
	"Dot",
	"Equals",
	"Comma",

	-- Keywords
	"Local",

	
	"EndOfFile"
}

local Enum = {}

for i, v in ipairs(TokenTypes) do
	Enum[v] = i
end

return Enum