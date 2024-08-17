# TrashCode
![:trash can:](/images/trashcan.png)
a programming language that supports practically nothing.

## Benchmarking
A simple benchmark in TrashCode would look like this: (written in v0.2-beta)
```lua
local a = 5
local g = 0
local start = program.timerStart()
for i = 1, 1000000 do
	g = i + a
end
local diff = program.timerStop(5)
print(diff)
```
