local pixelbox = require("lib.pixelbox")

local cmgr     = require("core.cmgr")
local bus      = require("core.bus")
local handlers = require("core.handlers")

local update_thread = require("core.threads.update_thread")
local event_thread  = require("core.threads.event_thread")
local resize_thread = require("core.threads.resize_thread")
local key_thread    = require("core.threads.key_thread")

return function(ENV,libdir,...)
    local args = table.pack(...)
    local BUS = bus.register_bus(ENV)

    handlers(ENV)

    BUS.graphics.stack[BUS.graphics.stack.current_pos] = 
        ENV.utils.table.deepcopy(BUS.graphics.stack.default)

    local function start_execution(program,path,terminal,parent,ox,oy)
        local w,h = terminal.getSize()
        local ok = pcall(function()
            BUS.graphics.monitor = peripheral.getName(parent)
        end)
        if not ok then BUS.graphics.monitor = "term_object" end
        BUS.graphics.w,BUS.graphics.h = w*2,h*3
        BUS.graphics.display = pixelbox.new(terminal)
        BUS.graphics.display_source = terminal
        BUS.graphics.event_offset = vector.new(ox,oy)
        BUS.clr_instance.update_palette(terminal)
        for x,y in ENV.utils.table.map_iterator(BUS.graphics.w,BUS.graphics.h) do
            BUS.graphics.buffer[y][x] = {0,0,0,1}
        end
        if type(program[1]) == "function" then
            local old_path = package.path
            ENV.package.path = string.format(
                "/%s/modules/required/?.lua;/%s/?.lua;/rom/modules/main/?.lua",
                libdir,fs.getDir(path) or ""
            )
            setfenv(program[1],ENV)(table.unpack(args,1,args.n))
            ENV.package.path = old_path
        else
            error(program[2],0)
        end

        local main   = update_thread.make(ENV,BUS,args)
        local event  = event_thread .make(ENV,BUS,args)
        local resize = resize_thread.make(ENV,BUS,parent)
        local key_h  = key_thread   .make(ENV,BUS)

        local ok,err = cmgr.start(function()
            return BUS.running
        end,{},main,event,resize,key_h)

        if not ok and ENV.love.errorhandler then
            if ENV.love.errorhandler(err) then
                error(err,2)
            end
        elseif not ok then
            error(err,2)
        end
    end

    ENV.love.timer    = require("modules.timer")   (BUS)
    ENV.love.event    = require("modules.event")   (BUS)
    ENV.love.graphics = require("modules.graphics")(BUS)

    require("modules.love")(BUS)

    return start_execution
end