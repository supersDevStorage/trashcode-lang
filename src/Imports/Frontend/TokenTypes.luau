local tokenTypeStrings = {
	-- Literals
	"Number",
	"String",
	"Identifier",
	-- Grouping
	"Equals", -- =
	"Dot",
	"StringConcat",
	"OpenParen", "CloseParen", -- (, )
	"OpenBrace", "CloseBrace", -- {, }
	"OpenBracket", "CloseBracket", -- [, ]
	"Comma", "ArrayEquals",
	"BinaryOperator",
	"LessThanSign",
	"GreaterThanSign",
	"EndOfStmt",
	"ConditionalEquals",
	"NotEquals",
	"CompoundEquals",
	-- Keywords
	"Reserved",
	"Let",
	"Const",
	"Function",
	"EndOfScope",
	"Return",
	"For",
	"While",
	"If",
	"Then",
	"Do",
	"Else",
	"Break",

	-- Miscellaneous
	"Comment",
	
	
	"EndOfFile" -- this is set to a high value so that any future additions to this array dont hit this index (kinda useless but im quirky)
}

local function arrayToEnum(array : {string}) -- basically converter into an enum
	-- keep in mind that this starts at 1 cuz lua arrays start at 1
	local newEnum = {}
	
	for i, v in ipairs(array) do
		newEnum[v] = i
	end
	
	return newEnum
end

return arrayToEnum(tokenTypeStrings)
