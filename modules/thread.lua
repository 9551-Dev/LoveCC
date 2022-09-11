local generic = require("common.generic")

local object = require("core.object")

local thread = {}

return function(BUS)
    local objects = {
        thread={__index=object.new{
            getError  = function(this) return this.error end,
            isRunning = function(this) return coroutine.status(this.c) == "running" end,
            start     = function(this,...)
                if not this.started then
                    coroutine.resume(this.c,...)
                    this.started = true
                end
            end,
            wait      = function(this)
                while coroutine.status(this.c) ~= "dead" do
                    generic.precise_sleep(0.01)
                end
            end
        },__tostring=function() return "LoveCC_Thread" end}
    }

    function thread.newThread(code)
        local id = generic.uuid4()

        local func,msg = load(code or "","Thread error","t",BUS.ENV)

        if func then

            BUS.thread.coro[id] = {
                c = coroutine.create(function(...)
                    coroutine.yield()
                    func(...)
                end),
                obj_type="Thread",
                stored_in=BUS.thread.coro,
                under=id,
                started=false,
            }

            local obj = setmetatable(BUS.thread.coro[id],objects.thread)
            obj:__attach()
            BUS.thread.coro[id].object = obj

            return obj
        else return false,msg end
    end

    return thread
end