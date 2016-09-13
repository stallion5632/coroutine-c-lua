--client.lua
-- send user input data to server and print data from server

local socket = require("socket")

local host = "localhost"
local port = 8888
local sock = assert(socket.connect(host, port))
sock:settimeout(0)

function start_client()
	print("Press enter after input something:")

	local input, recvt, sendt, status

	while true do
		input = io.read()
		if #input > 0 then
			assert(sock:send(input .. "\n"))
		end

		recvt = socket.select({sock}, nil, 1) 
		--recvt, sendt, status
		while #recvt > 0 do
			local receive, status = sock:receive()

			if status ~= "closed" then
				if receive then
					print ('recv from server:'..receive)
					recvt = socket.select({sock}, nil, 1)
				end
			else
				break
			end
		end
	end
end

start_client()
