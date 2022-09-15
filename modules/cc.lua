local cc = {}

local CEIL = math.ceil

return function(BUS)

    function cc.get_bus()
        return BUS
    end

    function cc.quantize(enable)
        BUS.cc.quantize = enable
    end

    function cc.fps_limit(limit)
        BUS.cc.frame_time_min = 1/limit
    end

    function cc.clamp_color(color,limit)
        return CEIL(color*limit)/limit
    end

    function cc.reserve_color(r,g,b)
        local res = BUS.cc.reserved_colors
        res[#res+1] = {r,g,b}
    end

    function cc.pop_reserved_color()
        local res = BUS.cc.reserved_colors
        res[#res] = nil
    end

    function cc.get_reserved_colors()
        return BUS.cc.reserved_colors
    end

    function cc.remove_reserved_colors()
        BUS.cc.reserved_colors = {}
    end

    return cc
end