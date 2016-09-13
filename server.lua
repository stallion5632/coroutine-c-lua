-- server.lua
--listen connection from client, and make a coroutine for each connection
--each coroutine recv data from client and send data back to client

local socket = require('socket')

local host = 'localhost'
local port = '8888'
local connections = {}
local threads = {}

--create coroutine to handle data from client
function create_handler(index)
	local handler = function()
		while true do
			local conn = connections[index]
			if conn == nil then
				break
			end
			local recvt, t, status = socket.select({conn}, nil, 1)
			if #recvt > 0 then
				local receive, status = conn:receive()
				if status ~= 'closed' then
					if receive then
						print("Receive Client " .. index.. " : " ..receive)
						assert(conn:send(receive .. '\n'))
					end
				else
					print('Client ' .. index .. ' disconnected')
					connections[index].close()
					connections[index] = nil
					threads[index] = nil
				end
			end
			--yield, stop execution of this coroutine
			coroutine.yield()
		end
	end
	local handler = coroutine.create(handler)
	return handler
end

function accept_connection(index, conn)
	print("accepted new socket ,id = " .. index)
	connections[index] = conn
	threads[index] = create_handler(index)
end

--schedule all clients
function dispatch()
	for i, thread in ipairs(threads) do
		coroutine.resume(threads[i])
	end
end

function start_server()
	local server = assert(socket.bind(host, port, 1024))
	print("Server Start " .. host .. ":" .. port)
	server:settimeout(0)

	local count = 0

	while true do 
		--accept new connection
		local conn = server:accept()
		if conn then
			count = count + 1
			accept_connection(count, conn)
		end

		--deal data from connection
		dispatch()
	end
end
start_server()
