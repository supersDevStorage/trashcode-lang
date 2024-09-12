local input = io.open("testCode.txt"):read("a")
inspect = require("inspect")

local Parser = require("Frontend.parser")

print(inspect(Parser:produceAST(input)))