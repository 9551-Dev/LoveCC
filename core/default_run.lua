local function build_run(love,args)
    function love.run()
        if love.load then love.load(table.unpack(args,1,args.n)) end
        if love.timer then love.timer.step() end
        local dt = 0
        return function()
            if love.event then
                love.event.pump()
                for name, a,b,c,d,e,f in love.event.poll() do
                    if name == "quit" then
                        if not love.quit or not love.quit() then
                            return a or 0
                        end
                    end
                    love.handlers[name](a,b,c,d,e,f)
                end
            end
            if love.timer then dt = love.timer.step() end
            if love.update then love.update(dt) end
            if love.graphics and love.graphics.isActive() then
                love.graphics.origin()
                love.graphics.clear(love.graphics.getBackgroundColor())
                if love.draw then love.draw() end
                love.graphics.present()
            end
            if love.timer then love.timer.sleep(0.001) end
        end
    end
end

return build_run