local pixelbox = require("lib.pixelbox").new

return {make=function(ENV,BUS,terminal)
    local last_x,last_y = terminal.getSize()
    return coroutine.create(function()
        while true do
            local cx,cy = terminal.getSize()
            if cx ~= last_x or cy ~= last_y 
                and BUS.window.resizable
                and cx >= BUS.window.min_width
                and cy >= BUS.window.min_height
            then
                BUS.graphics.display:get().reposition(1,1,cx,cy)
                BUS.graphics.display:resize(cx,cy)
                BUS.graphics.w = cx*2
                BUS.graphics.h = cy*3
                last_x,last_y = cx,cy
            end
            sleep(0.1)
        end
    end)
end}