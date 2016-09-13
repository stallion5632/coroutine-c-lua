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