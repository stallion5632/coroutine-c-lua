## 进程、线程、协程

在操作系统中，进程拥有自己独立的内存空间，多个进程同时运行不会相互干扰，但是进程之间的通信比较麻烦；线程拥有独立的栈但共享内存，因此数据共享比较容易，但是多线程中需要利用加锁来进行访问控制：这是个非常头痛的问题，不加锁非常容易导致数据的错误，加锁容易出现死锁。多线程在多个核上同时运行，程序员根本无法控制程序具体的运行过程，难以调试。而且线程的切换经常需要深入到内核，因此线程的切换代价还是比较大的。

协程coroutine拥有自己的栈和局部变量，相互之间共享全局变量。任何时候只有一个协程在真正运行，程序员能够控制协程的切换和运行，因此协程的程序相比多线程编程来说轻松很多。由于协程是用户级线程，因为协程的切换代价很小。

## 协程的挂起

程序员能够控制协程的切换，这句话需要认真理解下。程序员通过yield让协程在空闲（比如等待io，网络数据未到达）时放弃执行权，通过resume调度协程运行。协程一旦开始运行就不会结束，直到遇到yield交出执行权。Yield和resume这一对控制可以比较方便地实现程序之间的“等待”需求，即“异步逻辑”。总结起来，就是协程可以比较方便地实现用同步的方式编写异步的逻辑。

## “生产者-消费者”

异步逻辑最常见的例子便是“生产者-消费者”案例，消费者consumer需要等待生产者producer，只有生产了数据才能消费，这便是一个“等待的异步需求”。

## Lua中协程常用接口：

| coroutine接口 |	说明: |
| ------- |	------ |
| coroutine.create(func) |	创建一个协程
| coroutine.resume(coroutine, [arg1, arg2..]) |	执行协程，第一次从头开始运行，之后每次从上次yield处开始运行，每次运行到遇到yield或者协程结束 |
| coroutine.yield(…) |	挂起当前协程，交出执行权 |


## 利用协程的yield和resume实现的生产者-消费者代码：
```
--producer
function producer()
    return coroutine.create(
        function()
            while true do
                local a = io.read()
                --hang up
                coroutine.yield(a)
            end
        end
    )
end

--consumer
function consumer(pro)
    while true do
        local s, v = coroutine.resume(pro)
        print ('s='..tostring(s)..', v='..v)
    end
end
p = producer()
consumer(p)
```
coroutine实现server

接下来再看一个用协程处理客户端请求的服务器：server主线程接收client请求，接受连接上来后为每个client创建一个coroutine，这个coroutine监听client发来的数据如果有数据发来那么进行处理，如果没有数据那么yield挂起交出执行权。
```
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
```
coroutine实现client
```
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
```

## 执行结果
```
--server
$ lua server.lua 
Server Start localhost:8888
accepted new socket ,id = 1
accepted new socket ,id = 2
Receive Client 1 : 1111111
Receive Client 2 : 222222
Client 1 disconnected
Client 2 disconnecte
```

```
--client1
$ lua client.lua 
Press enter after input something:
1111111
recv from server:1111111
^C^C
```

```
--client2
$ lua client.lua 
Press enter after input something:
222222
recv from server:222222
^C^C
```
- [协程Coroutine——用同步的方式编写异步的逻辑](http://blog.csdn.net/djsaiofjasdfsa/article/details/48846591) 
- [【深入Lua】理解Lua中最强大的特性-coroutine（协程）](http://my.oschina.net/wangxuanyihaha/blog/186401)
- [风格之争：Coroutine模型 vs 非阻塞/异步IO(callback)](http://www.kuqin.com/system-analysis/20110910/264592.html)
