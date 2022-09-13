local tbl = require("common.table_util")

local window = {}

return function(BUS)
    function window.close() end
    function window.fromPixels(x,y) return x,y end
    function window.getDPIScale() return 1 end
    function window.getDesktopDimensions()
        local w,h = BUS.graphics.display_source.getSize()
        return w*2,h*3
    end
    function window.getDisplayCount() return 1 end
    function window.getDisplayName() return BUS.graphics.monitor end
    function window.getDisplayOrientation(display_index)
        local w,h = BUS.graphics.display:get().getSize()
        if w > h then
            return "landscape"
        elseif h > w then
            return "portrait"
        end
        return "unknown"
    end
    function window.getFullscreen() return "exclusive" end
    function window.getFullscreenModes(display_index)
        local w,h = BUS.graphics.display:get().getSize()
        return {{width=w*2,height=h*3}}
    end
    function window.getIcon() error("love.window.getIcon is not implemented yet") end
    function window.getMode()
        local w,h = BUS.graphics.display:get().getSize()
        return w,h,tbl.deepcopy(BUS.window)
    end
    function window.getPosition() return 1,1,1 end
    function window.getSafeArea()
        return 1,1,BUS.graphics.display:get().getSize()
    end
    function window.getTitle()
        if _ENV.multishell then
            return multishell.getTitle(multishell.getCurrent())
        else return "" end
    end
    function window.getVSync() return BUS.window.vsync end
    function window.hasFocus() return true end
    function window.hasMouseFocus() return BUS.window.active end
    function window.isDisplaySleepEnabled() return BUS.window.allow_sleep end
    function window.isMaximized() return BUS.window.maximized end
    function window.isMinimized() return not BUS.window.maximized end
    function window.isOpen() return true end
    function window.isVisible() return BUS.window.active end
    function window.maximize() BUS.window.maximized = true  end
    function window.minimize() BUS.window.maximized = false end
    function window.requestAttention() end
    function window.restore() BUS.window.maximized = true end
    function window.setDisplaySleepEnabled(enable) BUS.window.allow_sleep = enable end
    function window.setFullscreen(fullscreen,tp)
        BUS.window.fullscreen = fullscreen
        BUS.window.fs_type = tp
        return true
    end
    function window.setIcon(imagedata) error("love.window.setIcon is not implemented yet") end
    function window.setMode(width,height,flags)
        BUS.graphics.display:get().reposition(1,1,width,height)
        BUS.graphics.display:resize(width,height)
        BUS.graphics.w = width*2
        BUS.graphics.h = height*3
        BUS.window = flags
        return true
    end
    function window.setPosition(x,y) end
    function window.setTitle(title)
        if _ENV.multishell then
            multishell.setTitle(multishell.getCurrent(),title)
            return true
        else return false end
    end
    function window.setVSync(vsync) BUS.window.vsync = vsync end
    function window.toPixels(x,y) return x,y end
    function window.updateMode(width,height,settings)
        BUS.graphics.display:get().reposition(1,1,width,height)
        BUS.graphics.display:resize(width,height)
        BUS.graphics.w = width*2
        BUS.graphics.h = height*3
        for k,v in pairs(settings) do
            BUS.window[k] = v
        end
        return true
    end

    return window
end