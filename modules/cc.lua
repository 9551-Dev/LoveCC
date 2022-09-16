local cc = {}

local CEIL = math.ceil

return function(BUS)

    function cc.get_bus()
        return BUS
    end

    function cc.quantize(enable)
        BUS.cc.quantize = enable
    end

    function cc.dither(enable)
        BUS.cc.dither = enable
    end

    function cc.dither_factor(factor)
        BUS.cc.dither_factor = factor
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

    function cc.reserve_spot(n,r,g,b)
        local sp = BUS.cc.reserved_spots
        sp[#sp+1] = {2^n,{r,g,b}}
    end

    function cc.pop_reserved_spot()
        local sp = BUS.cc.reserved_spots
        sp[#sp] = nil
    end

    function cc.remove_reserved_spots()
        BUS.cc.reserved_spots = {}
    end

    return cc
end