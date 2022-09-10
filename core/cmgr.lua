local lib_cmgr = {}
local newline = "\n"

function lib_cmgr.add_thread_pointer(threads,f)
    local t = {coro=coroutine.create(f)}
    threads[t] = t
end

local function unpack_ev(e)
    return table.unpack(e,1,e.n)
end

function lib_cmgr.start(toggle,thread_pointer,main_thread,...)
    local static_threads = {...}
    local static_thread_filters = {}
    local main_filter
    local e
    while coroutine.status(main_thread) ~= "dead" and type(e) == "nil" and toggle() do
        local ev = table.pack(os.pullEventRaw())
        if ev[1] == "terminate" then e = "Terminated" end
        if ev[1] == main_filter or not main_filter then
            local ok,ret = coroutine.resume(main_thread,unpack_ev(ev))
            if ok then main_filter = ret end
            if not ok and coroutine.status(main_thread) == "dead" then
                error("Error in main thread"..newline..tostring(ret),0)
            end
        end
        for k,v in pairs(static_threads) do
            local f = static_thread_filters[k]
            if ev[1] == f or not f then
                if coroutine.status(v) ~= "dead" then
                    local ok,ret = coroutine.resume(v,unpack_ev(ev))
                    if ok then static_thread_filters[k] = ret end
                    if not ok and coroutine.status(v) == "dead" then
                        e = ret
                    end
                else static_threads[k] = nil end
            end
        end
        for k,v in pairs(thread_pointer) do
            local filter = v.filter
            if ev[1] == filter or not filter then
                if coroutine.status(v) ~= "dead" then
                    local ok,ret = coroutine.resume(v.coro,unpack_ev(ev))
                    if ok then thread_pointer[k].filter = ret end
                    if not ok and coroutine.status(v.coro) == "dead" then
                        e = ret
                    end
                else thread_pointer[k] = nil end
            end
        end
    end
    if toggle() then error(e,0) end
end

return lib_cmgr