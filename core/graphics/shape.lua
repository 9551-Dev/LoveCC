local shapes = {}
local CEIL = math.ceil
local FLOOR = math.floor
local ABS = math.abs
local MIN = math.min

local function draw_flat_top_triangle(v0,v1,v2,caller)
    local v0x,v0y = v0.x,v0.y
    local v1x,v1y = v1.x,v1.y
    local v2x,v2y = v2.x,v2.y
    local m0 = (v2x - v0x) / (v2y - v0y)
    local m1 = (v2x - v1x) / (v2y - v1y)
    local y_start = CEIL(v0y - 0.5)
    local y_end   = CEIL(v2y - 0.5) - 1
    for y=y_start,y_end do 
        local px0 = m0 * (y + 0.5 - v0y) + v0x
        local px1 = m1 * (y + 0.5 - v1y) + v1x
        local x_start = CEIL(px0 - 0.5)
        local x_end   = CEIL(px1 - 0.5)
        for x=x_start,x_end do
            caller(x,y)
        end
    end
end

local function draw_flat_bottom_triangle(v0,v1,v2,caller)
    local v0x,v0y = v0.x,v0.y
    local v1x,v1y = v1.x,v1.y
    local v2x,v2y = v2.x,v2.y
    local m0 = (v1x - v0x) / (v1y - v0y)
    local m1 = (v2x - v0x) / (v2y - v0y)
    local y_start = CEIL(v0y - 0.5)
    local y_end   = CEIL(v2y - 0.5) - 1
    for y=y_start,y_end do 
        local px0 = m0 * (y + 0.5 - v0y) + v0x
        local px1 = m1 * (y + 0.5 - v0y) + v0x
        local x_start = CEIL(px0 - 0.5)
        local x_end   = CEIL(px1 - 0.5)
        for x=x_start,x_end do
            caller(x,y)
        end
    end
end

function shapes.get_triangle_points(vector0,vector1,vector2,caller)
    if vector1.y < vector0.y then vector0,vector1 = vector1,vector0 end
    if vector2.y < vector1.y then vector1,vector2 = vector2,vector1 end
    if vector1.y < vector0.y then vector0,vector1 = vector1,vector0 end
    if vector0.y == vector1.y then
        if vector1.x < vector0.x then vector0,vector1 = vector1,vector0 end
        draw_flat_top_triangle(vector0,vector1,vector2,caller)
    elseif vector1.y == vector2.y then
        if vector2.x < vector1.x then vector1,vector2 = vector2,vector1 end
        draw_flat_bottom_triangle(vector0,vector1,vector2,caller)
    else
        local alpha_split = (vector1.y-vector0.y) / (vector2.y-vector0.y)
        local split_vertex = { 
            x = vector0.x + ((vector2.x - vector0.x) * alpha_split),      
            y = vector0.y + ((vector2.y - vector0.y) * alpha_split),
        }
        if vector1.x < split_vertex.x then
            draw_flat_bottom_triangle(vector0,vector1,split_vertex,caller)
            draw_flat_top_triangle   (vector1,split_vertex,vector2,caller)
        else
            draw_flat_bottom_triangle(vector0,split_vertex,vector1,caller)
            draw_flat_top_triangle   (split_vertex,vector1,vector2,caller)
        end
    end
end

function shapes.get_elipse_points(radius_x,radius_y,xc,yc,filled,caller)
    local rx,ry = CEIL(FLOOR(radius_x-0.5)/2),CEIL(FLOOR(radius_y-0.5)/2)
    local x,y=0,ry
    local d1 = ((ry * ry) - (rx * rx * ry) + (0.25 * rx * rx))
    local dx = 2*ry^2*x
    local dy = 2*rx^2*y
    while dx < dy do
        caller(x+xc,y+yc)
        caller(-x+xc,y+yc)
        caller(x+xc,-y+yc)
        caller(-x+xc,-y+yc)
        if filled then
            for y=-y+yc+1,y+yc-1 do
                caller(x+xc,y)
                caller(-x+xc,y)
            end
        end
        if d1 < 0 then
            x = x + 1
            dx = dx + 2*ry^2
            d1 = d1 + dx + ry^2
        else
            x,y = x+1,y-1
            dx = dx + 2*ry^2
            dy = dy - 2*rx^2
            d1 = d1 + dx - dy + ry^2
        end
    end
    local d2 = (((ry * ry) * ((x + 0.5) * (x + 0.5))) + ((rx * rx) * ((y - 1) * (y - 1))) - (rx * rx * ry * ry))
    while y >= 0 do
        caller(x+xc,y+yc)
        caller(-x+xc,y+yc)
        caller(x+xc,-y+yc)
        caller(-x+xc,-y+yc)
        if filled then
            for y=-y+yc,y+yc do
                caller(x+xc,y)
                caller(-x+xc,y)
            end
        end
        if d2 > 0 then
            y = y - 1
            dy = dy - 2*rx^2
            d2 = d2 + rx^2 - dy
        else
            y = y - 1
            x = x + 1
            dy = dy - 2*rx^2
            dx = dx + 2*ry^2
            d2 = d2 + dx - dy + rx^2
        end
    end
end

function shapes.get_line_points(startX,startY,endX,endY,caller)
    startX,startY,endX,endY = FLOOR(startX),FLOOR(startY),FLOOR(endX),FLOOR(endY)
    if startX == endX and startY == endY then return {{x=startX,y=startY}} end
    local minX = MIN(startX, endX)
    local maxX, minY, maxY
    if minX == startX then minY,maxX,maxY = startY,endX,endY
    else minY,maxX,maxY = endY,startX,startY end
    local xDiff,yDiff = maxX - minX,maxY - minY
    if xDiff > ABS(yDiff) then
        local y = minY
        local dy = yDiff / xDiff
        for x = minX, maxX do
            caller(x,FLOOR(y + 0.5))
            y = y + dy
        end
    else
        local x,dx = minX,xDiff / yDiff
        if maxY >= minY then
            for y = minY, maxY do
                caller(FLOOR(x + 0.5),y)
                x = x + dx
            end
        else
            for y = minY, maxY, -1 do
                caller(FLOOR(x + 0.5),y)
                x = x - dx
            end
        end
    end
end

return shapes