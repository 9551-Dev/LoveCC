local generic = require("common.generic")

local object = require("core.object")

local thread = {}

local function is_code(input)
    local _,newlines   = input:gsub("\n","\n")
    local _,semicolons = input:gsub(";",";")
    local _,spaces     = input:gsub(" "," ")
    if newlines > 1 or semicolons > 1 or spaces > 1 or #input > 1024 then
        return true
    else return false end
end

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

        if not is_code(code) then
            local selected_path = fs.combine(BUS.instance.gamedir,code)
            local file,reason = fs.open(selected_path,"r")
            if file then
                code = file.readAll()
            else return false,reason end
        end

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