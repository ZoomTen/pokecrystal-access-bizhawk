luanet.load_assembly("System")
local TcpClient = luanet.import_type("System.Net.Sockets.TcpClient")
local StreamWriter = luanet.import_type("System.IO.StreamWriter")
local client = TcpClient("127.0.0.1", 61226)
local stream = client:GetStream()
local writer = StreamWriter(stream)

local function output(s)
	print(s)
	writer:Write("POST /speak HTTP/1.1\r\nHost: 127.0.0.1:61226\r\nContent-Length: " .. #s .. "\r\n\r\n" .. s)
	writer:Flush()
end

local function silence()
end

local function play_sound(file, type, pan, vol)
	print(file, type, pan, vol)
	writer:Write("POST /sound HTTP/1.1\r\nHost: 127.0.0.1:61226\r\nContent-Length: " .. #file .. "\r\n\r\n" .. file)
	writer:Flush()
end

return { output = output, silence = silence, play_sound = play_sound }
