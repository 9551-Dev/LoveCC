local keypressed
local keyreleased

return {make=function(ENV,BUS,args)
    return coroutine.create(function()
        while true do
            local ev = table.pack(os.pullEventRaw())
        end
    end)
end}