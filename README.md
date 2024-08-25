# TrashCode
a programming language that supports practically nothing.

## Benchmarking

### Perfect square benchmark (v0.6-beta)
Averaged 1288.920ms at runtime, performed 20 tests total.
### Perfect square benchmark (v0.5-beta)
Averaged 1774.142ms at runtime, performed 20 tests total.

Code ran: (for both versions above)
```lua
local endNum = 10000 -- the cutoff point at which the squares of j will no longer be checked against i
local squareLargerThanEnd = 1 -- the upper boundary of which the squares of j would exceed endNum

while (squareLargerThanEnd * squareLargerThanEnd) < endNum do
	squareLargerThanEnd = squareLargerThanEnd + 1
end

for i = 1, endNum do
	for j = 1, (squareLargerThanEnd - 1) do
		if (j * j) == i then
			print("Perfect square: " .. i)
		end
	end
end
```

### Perfect square benchmark (v0.4.1-beta)
Averaged: 1279.223ms at runtime, performed 10 tests total.

Code ran: (for the version above)
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
