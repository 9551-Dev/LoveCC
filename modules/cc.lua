local cc = {}

return function(BUS)

    function cc.get_bus()
        return BUS
    end

    function cc.quantize(enable)
        BUS.cc.quantize = enable
    end

    function cc.quantize_quality(quality)
        BUS.cc.quantize_quality = quality
    end

    function cc.fps_limit(limit)
        BUS.cc.frame_time_min = 1/limit
    end

    return cc
end