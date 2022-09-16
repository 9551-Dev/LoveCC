return {build=function(BUS)
    local graphics = BUS.graphics
    local buff = graphics.buffer

    local CEIL = math.ceil
    local CONST_1 = 7/16
    local CONST_2 = 3/16
    local CONST_3 = 5/16
    local CONST_4 = 1/16

    local function sub_color(c1,c2)
        return {
            c1[1] - c2[1],
            c1[2] - c2[2],
            c1[3] - c2[3],
        }
    end

    return {dither=function()
        local factor = BUS.cc.dither_factor
        for y=1,graphics.h do
            for x=1,graphics.w do

                local b_cent = buff[y][x]
                local old = {
                    b_cent[1],b_cent[2],b_cent[3]
                }
                buff[y][x] = {
                    CEIL(factor*b_cent[1]) * (1/factor),
                    CEIL(factor*b_cent[2]) * (1/factor),
                    CEIL(factor*b_cent[3]) * (1/factor)
                }

                local err = sub_color(old,b_cent)

                local b_right = buff[y][x+1]
                if b_right then buff[y][x+1] = {
                    b_right[1] + err[1] * CONST_1,
                    b_right[2] + err[2] * CONST_1,
                    b_right[3] + err[3] * CONST_1
                } end

                local b_topleft = buff[y+1][x-1]
                if b_topleft then buff[y+1][x-1] = {
                    b_topleft[1] + err[1] * CONST_2,
                    b_topleft[2] + err[2] * CONST_2,
                    b_topleft[3] + err[3] * CONST_2
                } end

                local b_top = buff[y+1][x]
                if b_top then buff[y+1][x] = {
                    b_top[1] + err[1] * CONST_3,
                    b_top[2] + err[2] * CONST_3,
                    b_top[3] + err[3] * CONST_3
                } end

                local b_topright = buff[y+1][x+1]
                if b_topright then buff[y+1][x+1] = {
                    b_topright[1] + err[1] * CONST_4,
                    b_topright[2] + err[2] * CONST_4,
                    b_topright[3] + err[3] * CONST_4
                } end
            end
        end
    end}
end}