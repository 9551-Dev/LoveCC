local tbl = require("common.table_util")

local SQRT = math.sqrt
local CEIL = math.ceil

return {build=function(BUS)
    local graphics = BUS.graphics

    local function get_distance(p1,p2)
        return SQRT(
            (p2[1]-p1[1])^2 +
            (p2[2]-p1[2])^2 +
            (p2[3]-p1[3])^2
        )
    end
    local function add_colors(p1,p2)
        return {
            p1[1] + p2[1],
            p1[2] + p2[2],
            p1[3] + p2[3],
        }
    end
    local function get_avg(group)
        local total = group.total
        return {
            group.avg[1]/total,
            group.avg[2]/total,
            group.avg[3]/total
        }
    end

    local function round_256(c)
        return {
            CEIL(c[1]*256)/256,
            CEIL(c[2]*256)/256,
            CEIL(c[3]*256)/256
        }
    end

    local function compare(c1,c2)
        return  c1[1] == c2[1]
            and c1[2] == c2[2]
            and c1[3] == c2[3]
    end

    return {quantize=function()
        local centroids = {}

        for i=1,16 do
            local random_r = math.random()
            local random_g = math.random()
            local random_b = math.random()

            centroids[i] = {random_r,random_g,random_b}
        end

        local ret = {}
        for i=1,BUS.cc.quantize_quality do
            local groups = {}
            local averages = {}
            for i=1,16 do groups[centroids[i]] = {total=0,avg={0,0,0},index=i} end
            for x,y in tbl.map_iterator(graphics.w,graphics.h) do
                local c = graphics.buffer[y][x]
                local distance = math.huge
                local closest_centroid
                for k,v in pairs(centroids) do
                    local d = get_distance(c,v)
                    if d < distance then
                        closest_centroid = v
                        distance = d
                    end
                end
                local centr = groups[closest_centroid]
                centr.total = centr.total + 1
                centr.avg   = add_colors(c,centr.avg)
            end
            for k,v in pairs(groups) do
                if v.total > 0 then
                    local avg = get_avg(v)
                    averages[v.index] = avg
                else
                    averages[v.index] = {-1,-1,-1}
                end
            end
            centroids = averages
            ret = averages
        end
        return ret
    end}
end}