local graphics = {}

local tbl = require("common.table_util")
local clr = require("common.color_util")

local UNPACK = table.unpack
local CEIL = math.ceil

return function(BUS)

    BUS.clr_instance = clr

    local stack = BUS.graphics.stack

    local function get_stack()
        return stack[stack.current_pos]
    end

    local function apply_transfomations(x,y)
        local stck = get_stack()
        return
            x + stck.translate[1],
            y + stck.translate[2]
    end

    local function blend_colors(existing,additional)
        local blend = stack[stack.current_pos].blending
        return clr.blend[blend.mode][blend.alphamode](existing,additional)
    end

    local function add_color_xy(x,y,c)
        local x,y = apply_transfomations(x,y)
        x = CEIL(x-0.5)
        y = CEIL(y-0.5)
        if x>0 and y>0 and x<BUS.graphics.w and y<BUS.graphics.h then
            local bpos = BUS.graphics.buffer[y]
            bpos[x] = blend_colors(bpos[x],c)
        end
    end

    function graphics.isActive() return BUS.window.active end
    function graphics.origin()
        local stck = get_stack()
        stck.translate = tbl.deepcopy(stack.default.translate)

        --love.graphics.scale
        --love.graphics.rotate
        --love.graphics.shrear
    end

    function graphics.makeDefault()
        stack[stack.current_pos] = tbl.deepcopy(stack.default)
    end

    function graphics.getBackgroundColor()
        return UNPACK(stack[stack.current_pos].background_color)
    end

    function graphics.clear(r,g,b,a)
        for x,y in tbl.map_iterator(BUS.graphics.w,BUS.graphics.h) do
            BUS.graphics.buffer[y][x] = {r,g,b,a or 1}
        end
    end
    function graphics.present()
        for x,y in tbl.map_iterator(BUS.graphics.w,BUS.graphics.h) do
            local rgb = BUS.graphics.buffer[y][x]
            local c = clr.find_closest_color(rgb[1],rgb[2],rgb[3])
            BUS.graphics.display:set_pixel_raw(x,y,c)
        end
        BUS.graphics.display:push_updates()
        BUS.graphics.display:draw()
    end

    function graphics.setColor(red,green,blue,alpha)
        local stck = get_stack()
        stck.color = {red,green,blue,alpha or 1}
    end
    function graphics.getColor()
        return tbl.deepcopy(get_stack().color)
    end

    function graphics.points(...)
        local points = {...}
        local stck = get_stack()
        if type(points[1]) == "table" then points = points[1] end
        local c = tbl.deepcopy(stck.color)
        local p_offset = CEIL((stck.point_size-1)/2+0.5)
        for i=1,#points,2 do
            for a=1,stck.point_size do for b=1,stck.point_size do
                add_color_xy(
                    CEIL(points[i]-p_offset+a-0.5),
                    CEIL(points[i+1]-p_offset+b-0.5)
                ,c)
            end end
        end
    end

    function graphics.setBlendMode(mode,alphamode)
        local stck = get_stack()
        stck.blending.mode = mode or "alpha"
        stck.blending.alphamode = alphamode or "alphamultiply"
    end
    function graphics.getblendMode()
        local stck = get_stack()
        return stck.blending.mode,stck.blending.alphamode
    end

    function graphics.setPointSize(size)
        local stck = get_stack()
        stck.point_size = size
    end
    function graphics.getPointSize()
        local stck = get_stack()
        return stck.point_size
    end

    function graphics.translate(dx,dy)
        local stck = get_stack()
        stck.translate = {dx,dy}
    end

    function graphics.push()
        local pos = stack.current_pos
        stack.current_pos = pos + 1
        stack[pos+1] = tbl.deepcopy(stack[pos])
    end
    function graphics.pop()
        local pos = stack.current_pos
        stack[pos] = nil
        stack.current_pos = pos - 1
    end
    function graphics.getStackDepth()
        return #stack
    end

    return graphics
end