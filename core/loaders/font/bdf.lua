local read_font = require("lib.readBDFFont")

local tbl = require("common.table_util")

return {read=function(path)
    local font_data = tbl.createNDarray(2)

    local file = fs.open(path,"r")
    local data = file.readAll()
    file.close()

    local font = read_font(data)

    for k,v in pairs(font.chars) do
        local size = v.bounds
        local map = v.bitmap
        for x,y in tbl.map_iterator(size.width,size.height) do
            if type(map[y][x]) ~= "nil" then
                font_data[k][y][x] = map[y][x]
            else font_data[k][y][x] = false end
        end
        font_data[k].bounds = v.bounds
    end

    font_data.meta = {
        ascent = font.ascent,
        descent = font.descent,
        filter={
            min = "nearest",
            mag = "nearest",
            anisotropy = 0
        },
        size={
            height=font.size.px+font.descent
        },
        line_height=1,
        bounds = font.bounds
    }

    return font_data
end}