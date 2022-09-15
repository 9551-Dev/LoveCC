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

    return cc
end