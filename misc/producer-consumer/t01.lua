co = coroutine.create(
function()
    for i=1,3 do
        print('co', i)
        coroutine.yield()
    end
end
)

function costatus()
    print('resume:', coroutine.resume(co))
    print('status:', coroutine.status(co))
	print()
end

print(co)
costatus()
costatus()
costatus()
costatus()
costatus()

--[[
thread: 0x25381b0
co	1
resume:	true
status:	suspended

co	2
resume:	true
status:	suspended

co	3
resume:	true
status:	suspended

resume:	true
status:	dead

resume:	false	cannot resume dead coroutine
status:	dead
--]]
