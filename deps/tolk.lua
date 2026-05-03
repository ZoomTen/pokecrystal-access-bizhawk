-- local encoding = require("encoding")
local function output(s)
	print(s)
end

local function silence()
end

local function play_sound(file, type, pan, vol)
	print(file, type, pan, vol)
end

return { output = output, silence = silence, play_sound = play_sound }
