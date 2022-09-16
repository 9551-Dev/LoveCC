local graphics = {}

local tbl   = require("common.table_util")
local clr   = require("common.color_util")
local shape = require("core.graphics.shape")
local quantize = require("core.graphics.quantize")
local dither = require("core.graphics.dither")

local UNPACK = table.unpack
local CEIL = math.ceil

return function(BUS)

    local quantizer = quantize.build(BUS)
    local ditherer  = dither  .build(BUS)

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
        local pal
        if BUS.cc.quantize then
            pal = clr.set_palette(BUS,quantizer.quantize())
        else
            clr.update_palette(BUS.graphics.display_source)
        end
        if BUS.cc.dither then ditherer.dither() end
        for x,y in tbl.map_iterator(BUS.graphics.w,BUS.graphics.h) do
            local rgb = BUS.graphics.buffer[y][x]
            local c = clr.find_closest_color(rgb[1],rgb[2],rgb[3])
            BUS.graphics.display:set_pixel_raw(x,y,c)
        end
        BUS.graphics.display:push_updates()
        if pal then pal.push(BUS.graphics.display_source) end
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

    function graphics.line(...)
        local lines = {...}
        local stck = get_stack()
        if type(lines[1]) == "table" then lines = lines[1] end
        local c = tbl.deepcopy(stck.color)
        local p_offset = CEIL((stck.line_width-1)/2+0.5)
        local found_lut = tbl.createNDarray(1)
        for i=1,#lines,4 do
            for a=1,stck.line_width do for b=1,stck.line_width do
                shape.get_line_points(
                    lines[i],
                    lines[i+1],
                    lines[i+2],
                    lines[i+3],
                    function(x,y)
                        local x,y = CEIL(x-p_offset+a-0.5),CEIL(y-p_offset+b-0.5)
                        if not found_lut[x][y] then
                            add_color_xy(x,y,c)
                            found_lut[x][y] = true
                        end
                    end
                )
            end end
        end
    end

    function graphics.setBlendMode(mode,alphamode)
        local stck = get_stack()
        stck.blending.mode = mode or "alpha"
        stck.blending.alphamode = alphamode or "alphamultiply"
    end
    function graphics.getBlendMode()
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
    function graphics.getLineWidth()
        local stck = get_stack()
        return stck.line_width
    end
    function graphics.setLineWidth(size)
        local stck = get_stack()
        stck.line_width = size
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

    function graphics.getDimensions()
        return BUS.graphics.w,BUS.graphics.h
    end

    function graphics.newFont(path)
        return BUS.object.font.new(path)
    end
    function graphics.setFont(font)
        local stck = get_stack()
        stck.font = font
    end
    function graphics.getFont()
        return tbl.deepcopy(get_stack().font)
    end

    function graphics.print(text,x,y)
        local stck = get_stack()

        local x,y = x or 0,y or 0
        local color = stck.color

        local font = stck.font
        local height = font.meta.bounds.height
        for c in tostring(text):gmatch(".") do
            x = x + 1

            local char = font[c]
            for sx,sy in tbl.map_iterator(char.bounds.width,char.bounds.height) do
                local cy = sy
                if char.bounds.height < height then
                    cy = sy + (height-char.bounds.height) - char.bounds.y
                end
                local px = x + sx - 2
                local py = y + cy - 4
                if char[sy][sx] then
                    add_color_xy(px,py,color)
                end
            end

            x = x + char.bounds.width
        end
    end

    return graphics
end