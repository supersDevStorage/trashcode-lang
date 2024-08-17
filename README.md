# TrashCode
a programming language that supports practically nothing.

## Benchmarking
### Perfect square benchmark (v0.2.2-beta)
Averaged: 2031.483ms at runtime, performed 10 tests total.
```lua
local endNum = 10000
local squareLargerThanEnd = 1

while (squareLargerThanEnd * squareLargerThanEnd) < endNum do
	squareLargerThanEnd = squareLargerThanEnd + 1
end

for i = 1, endNum do
	for j = 1, squareLargerThanEnd do
		if (j * j) == i then
			print("Perfect square: " .. i)
		end
	end
end
```
