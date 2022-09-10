local pixelbox = require("lib.pixelbox")

local cmgr = require("core.cmgr")
local bus = require("core.bus")

local update_thread = require("core.threads.update_thread")
local event_thread  = require("core.threads.event_thread")
local resize_thread = require("core.threads.resize_thread")

return function(ENV,...)
    local args = table.pack(...)
    local BUS = bus.make_bus(ENV)

    BUS.graphics.stack[BUS.graphics.stack.current_pos] = 
        ENV.utils.table.deepcopy(BUS.graphics.stack.default)

    local function start_execution(program,path,terminal,parent,ox,oy)
        local w,h = terminal.getSize()
        BUS.graphics.w,BUS.graphics.h = w*2,h*3
        BUS.graphics.display = pixelbox.new(terminal)
        BUS.graphics.display_source = terminal
        BUS.graphics.event_offset = vector.new(ox,oy)
        BUS.clr_instance.update_palette(terminal)
        for x,y in ENV.utils.table.map_iterator(BUS.graphics.w,BUS.graphics.h) do
            BUS.graphics.buffer[y][x] = {0,0,0,1}
        end
        if program then
            local old_path = package.path
            ENV.package.path = string.format(
                "/%s/?.lua;/rom/modules/main/?.lua",
                fs.getDir(path) or ""
            )
            setfenv(program,ENV)(table.unpack(args,1,args.n))
            ENV.package.path = old_path
        end

        local main   = update_thread.make(ENV,BUS,args)
        local event  = event_thread .make(ENV,BUS,args)
        local resize = resize_thread.make(ENV,BUS,parent)

        local ok,err = cmgr.start(function()
            return BUS.running
        end,{},main,event,resize)

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