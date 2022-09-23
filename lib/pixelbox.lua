--[[
    * api for easy interaction with drawing characters
    * single file implementation of GuiH pixelbox api
]]

local EXPECT = require("cc.expect").expect

local PIXELBOX = {}
local OBJECT = {}
local api = {}
local graphic = {}

local CEIL  = math.ceil
local FLOOR = math.floor
local SQRT  = math.sqrt
local t_insert, t_unpack, t_sort, s_char, pairs = table.insert, table.unpack, table.sort, string.char, pairs

local chars = "0123456789abcdef"
graphic.to_blit = {}
graphic.logify  = {}
for i = 0, 15 do
    graphic.to_blit[2^i] = chars:sub(i + 1, i + 1)
    graphic.logify [2^i] = i
end

function PIXELBOX.INDEX_SYMBOL_CORDINATION(tbl,x,y,val)
    tbl[x+y*2-2] = val
    return tbl
end

function OBJECT:within(x,y)
    return x > 0
        and y > 0
        and x <= self.width*2
        and y <= self.height*3
end

function PIXELBOX.RESTORE(BOX,color)
    BOX.CANVAS = api.createNDarray(1)
    BOX.UPDATES = api.createNDarray(1)
    BOX.CHARS = api.createNDarray(1)
    for y=1,BOX.height*3 do
        for x=1,BOX.width*2 do
            BOX.CANVAS[y][x] = color
        end
    end
    for y=1,BOX.height do
        for x=1,BOX.width do
            BOX.CHARS[y][x] = {symbol=" ",background=graphic.to_blit[color],fg="f"}
        end
    end
    getmetatable(BOX.CANVAS).__tostring = function() return "PixelBOX_SCREEN_BUFFER" end
end

function OBJECT:push_updates()
    PIXELBOX.ASSERT(type(self)=="table","Please use \":\" when running this function")
    self.symbols = api.createNDarray(2)
    self.lines = api.create_blit_array(self.height)
    self.pixels = api.createNDarray(1)
    getmetatable(self.symbols).__tostring=function() return "PixelBOX.SYMBOL_BUFFER" end
    setmetatable(self.lines,{__tostring=function() return "PixelBOX.LINE_BUFFER" end})
    for y=1,self.height*3,3 do
        local layer_1 = self.CANVAS[y]
        local layer_2 = self.CANVAS[y+1]
        local layer_3 = self.CANVAS[y+2]
        for x=1,self.width*2,2 do
            local block_color = {
                layer_1[x],layer_1[x+1],
                layer_2[x],layer_2[x+1],
                layer_3[x],layer_3[x+1]
            }
            local B1 = layer_1[x]
            local SCREEN_X = CEIL(x/2)
            local SCREEN_Y = CEIL(y/3)
            local LINES_Y = self.lines[SCREEN_Y]
            local terminal_data = self.terminal_map[SCREEN_Y][SCREEN_X]
            if (self.UPDATES[SCREEN_Y][SCREEN_X] or not self.prev_data) and (terminal_data and terminal_data.clear) then
                local char,fg,bg = " ",colors.black,B1
                if not (block_color[2] == B1
                    and block_color[3] == B1
                    and block_color[4] == B1
                    and block_color[5] == B1
                    and block_color[6] == B1) then
                    char,fg,bg = graphic.build_drawing_char(block_color)
                    self.CHARS[y][x] = {symbol=char, background=graphic.to_blit[bg], fg=graphic.to_blit[fg]}
                end
                self.lines[SCREEN_Y] = {
                    LINES_Y[1]..char,
                    LINES_Y[2]..graphic.to_blit[fg],
                    LINES_Y[3]..graphic.to_blit[bg]
                }
            elseif terminal_data and not terminal_data.clear then
                self.lines[SCREEN_Y] = {
                    LINES_Y[1]..terminal_data[1],
                    LINES_Y[2]..graphic.to_blit[terminal_data[2]],
                    LINES_Y[3]..graphic.to_blit[terminal_data[3]]
                }
            else
                local prev_data = self.CHARS[y][x]
                self.lines[SCREEN_Y] = {
                    LINES_Y[1]..prev_data.symbol,
                    LINES_Y[2]..prev_data.fg,
                    LINES_Y[3]..prev_data.background
                }
            end
            self.pixels[y][x]     = block_color[1]
            self.pixels[y][x+1]   = block_color[2]
            self.pixels[y+1][x]   = block_color[3]
            self.pixels[y+1][x+1] = block_color[4]
            self.pixels[y+2][x]   = block_color[5]
            self.pixels[y+2][x+1] = block_color[5]
        end
    end
    self.UPDATES = api.createNDarray(1)
end

function OBJECT:get_pixel(x,y)
    PIXELBOX.ASSERT(type(self)=="table","Please use \":\" when running this function")
    EXPECT(1,x,"number")
    EXPECT(2,y,"number")
    assert(self.CANVAS[y] and self.CANVAS[y][x],"Out of range")
    return self.CANVAS[y][x]
end

function OBJECT:clear(color)
    PIXELBOX.ASSERT(type(self)=="table","Please use \":\" when running this function")
    EXPECT(1,color,"number")
    PIXELBOX.RESTORE(self,color)
end

function OBJECT:draw()
    PIXELBOX.ASSERT(type(self)=="table","Please use \":\" when running this function")
    if not self.lines then error("You must push_updates in order to draw",2) end
    for y,line in ipairs(self.lines) do
        self.term.setCursorPos(1,y)
        self.term.blit(
            table.unpack(line)
        )
    end
end

function OBJECT:set_pixel(x,y,color,thiccness,base)
    if not base then
        PIXELBOX.ASSERT(type(self)=="table","Please use \":\" when running this function")
        EXPECT(1,x,"number")
        EXPECT(2,y,"number")
        EXPECT(3,color,"number")
        PIXELBOX.ASSERT(x>0 and x<=self.width*2,"Out of range")
        PIXELBOX.ASSERT(y>0 and y<=self.height*3,"Out of range")
        thiccness = thiccness or 1
        local t_ratio = (thiccness-1)/2
        self:set_box(
            CEIL(x-t_ratio),
            CEIL(y-t_ratio),
            x+thiccness-1,y+thiccness-1,color,true
        )
    else
        local RELATIVE_X = CEIL(x/2)
        local RELATIVE_Y = CEIL(y/3)
        self.UPDATES[RELATIVE_Y][RELATIVE_X] = true
        self.CANVAS[y][x] = color
    end
end

function OBJECT:set_pixel_raw(x,y,color)
    local RELATIVE_X = CEIL(x/2)
    local RELATIVE_Y = CEIL(y/3)
    if not self.pixels or self.pixels[y][x] ~= color then
        self.UPDATES[RELATIVE_Y][RELATIVE_X] = true
    end
    self.CANVAS[y][x] = color
end

function OBJECT:set_box(sx,sy,ex,ey,color,check)
    if not check then
        PIXELBOX.ASSERT(type(self)=="table","Please use \":\" when running this function")
        EXPECT(1,sx,"number")
        EXPECT(2,sy,"number")
        EXPECT(3,ex,"number")
        EXPECT(4,ey,"number")
        EXPECT(5,color,"number")
    end
    for y=sy,ey do
        for x=sx,ex do
            if self:within(x,y) then
                local RELATIVE_X = CEIL(x/2)
                local RELATIVE_Y = CEIL(y/3)
                self.UPDATES[RELATIVE_Y][RELATIVE_X] = true
                self.CANVAS[y][x] = color
            end
        end
    end
end

function PIXELBOX.CREATE_TERM(pixelbox)
    local object = {}
    pixelbox.terminal_map = api.createNDarray(1)
    local map = pixelbox.terminal_map
    pixelbox.show_clears        = false

    local current_fg        = pixelbox.term.getTextColor()
    local current_bg        = pixelbox.term.getBackgroundColor()
    local cursor_x,cursor_y = pixelbox.term.getCursorPos()

    local function create_line(w,y,first)
        local line = {}
        for i=1,w do
            if not first then
                if not map[y][i].clear then
                    pixelbox.UPDATES[y][i] = true
                end
            end
            line[i] = {
                " ",current_fg,current_bg,clear=not pixelbox.show_clears
            }
        end
        return line
    end

    local function clear_object(object,first)
        local w,h = pixelbox.term.getSize()
        for y=1,h do
            object[y] = create_line(w,y,first)
        end
    end

    clear_object(map,true)

    function object.blit(chars,fg,bg)
        chars,fg,bg = chars:lower(),fg:lower(),bg:lower()
        local len = #chars
        if #bg == len and #fg == len then
            for i=1,#chars do
                local char  = chars:sub(i,i)
                local fgbit = 2^tonumber(fg:sub(i,i),16)
                local bgbit = 2^tonumber(bg:sub(i,i),16)
                map[cursor_y][cursor_x+i-1] = {char,fgbit,bgbit,clear=false}
            end
        else
            error("Arguments must be the same lenght",2)
        end
    end

    function object.write(chars)
        for i=1,#tostring(chars) do
            local char  = chars:sub(i,i)
            map[cursor_y][cursor_x+i-1] = {char,current_fg,current_bg,clear=false}
        end
    end

    function object.clear()
        clear_object(map)
    end

    function object.getLine(y)
        local char,bg,fg = "","",""
        local w = pixelbox.term.getSize()
        for x=1,w do
            local point = map[y][x]
            if not point.clear then
                char = char .. point[1]
                bg   = bg   .. point[2]
                fg   = fg   .. point[3]
            else
                char = char .. " "
                fg   = fg   .. graphic.to_blit[current_fg]
                bg   = bg   .. graphic.to_blit[current_bg]
            end
        end
        return char,bg,fg
    end

    function object.clearLine()
        local w = pixelbox.term.getSize()
        map[cursor_y] = create_line(w,cursor_y)
    end

    function object.scroll(y)
        local w,h = pixelbox.term.getSize()
        if y ~= 0 then
            local temp = api.createNDarray(1)
            clear_object(temp)
            for cy=1,h do
                if cy-y > h then break end
                temp[cy-y] = map[cy]
            end
            pixelbox.terminal_map = temp
            map = temp
        end
    end

    function object.setBackgroundColor (bg)  current_bg = bg end
    function object.setBackgroundColour(bg)  current_bg = bg end
    function object.setTextColor (fg)        current_fg = fg end
    function object.setTextColour(fg)        current_fg = fg end
    function object.setCursorPos(x,y)        cursor_x,cursor_y = x,y end
    function object.setCursorBlink(...)      pixelbox.term.setCursorBlink(...) end
    function object.restoreCursor()          pixelbox.term.setCursorPos(cursor_x,cursor_y) end
    function object.setPaletteColor (...)    pixelbox.term.setPaletteColor(...) end
    function object.setPaletteColour(...)    pixelbox.term.setPaletteColor(...) end
    function object.getBackgroundColor ()    return current_bg end
    function object.getBackgroundColour()    return current_bg end
    function object.getCursorBlink()         return pixelbox.term.getCursorBlink() end
    function object.getCursorPos()           return cursor_x,cursor_y end
    function object.getPaletteColor (...)    return pixelbox.term.getPaletteColor(...) end
    function object.getPaletteColour(...)    return pixelbox.term.getPaletteColor(...) end
    function object.getSize(...)             return pixelbox.term.getSize(...) end
    function object.getTextColor()           return current_fg end
    function object.getTextColour()          return current_fg end
    function object.isColor()                return pixelbox.term.isColor() end
    function object.isColour()               return pixelbox.term.isColor() end

    object.drawPixels      = pixelbox.term.drawPixels
    object.getVisible      = pixelbox.term.getVisible
    object.getPixel        = pixelbox.term.getPixel
    object.getPixels       = pixelbox.term.getPixels
    object.getPosition     = pixelbox.term.getPosition
    object.isVisible       = pixelbox.term.isVisible
    object.redraw          = pixelbox.term.redraw
    object.reposition      = pixelbox.term.reposition
    object.setVisible      = pixelbox.term.setVisible
    object.showMouse       = pixelbox.term.showMouse

    function object.clear_visibility(state) pixelbox.show_clears = state end

    return object
end

function PIXELBOX.ASSERT(condition,message)
    if not condition then error(message,3) end
    return condition
end

function OBJECT:resize(w,h)
    self.width,self.height = w,h
    PIXELBOX.RESTORE(self,colors.black)
    self.emu = PIXELBOX.CREATE_TERM(self)
end

function OBJECT:get()
    return self.term
end

function PIXELBOX.new(terminal,bg)
    EXPECT(1,terminal,"table")
    EXPECT(2,bg,"number","nil")
    local bg = bg or terminal.getBackgroundColor() or colors.black
    local BOX = {}
    local w,h = terminal.getSize()
    BOX.term = terminal
    setmetatable(BOX,{__index = OBJECT})
    BOX.width  = w
    BOX.height = h
    PIXELBOX.RESTORE(BOX,bg)
    BOX.emu = PIXELBOX.CREATE_TERM(BOX)
    return BOX
end

function api.createNDarray(n, tbl)
    tbl = tbl or {}
    if n == 0 then return tbl end
    setmetatable(tbl, {__index = function(t, k)
        local new = api.createNDarray(n - 1)
        t[k] = new
        return new
    end})
    return tbl
end
function api.create_blit_array(count)
    local out = {}
    for i=1,count do
        out[i] = {"","",""}
    end
    return out
end
function api.create_byte_array(count)
    local out = {}
    for i=1,count do
        out[i] = ""
    end
    return out
end
function api.merge_tables(...)
    local out = {}
    local n = 1
    for k,v in pairs({...}) do
        for _k,_v in pairs(v) do out[n] = _v n=n+1 end
    end
    return out
end
function api.get_closest_color(palette,c)
    local result = {}
    local n = 0
    for k,v in pairs(palette) do
        n=n+1
        result[n] = {
            dist=SQRT(
                (v[1]-c[1])^2 +
                (v[2]-c[2])^2 +
                (v[3]-c[3])^2
            ),  color=k
        }
    end
    table.sort(result,function(a,b) return a.dist < b.dist end)
    return result[1].color
end
function api.convert_color_255(r,g,b)
    return r*255,g*255,b*255
end
function api.hex_to_palette(hex)
    local r = (FLOOR(hex/0x10000)%256)/255
    local g = (FLOOR(hex/0x100)%256)/255
    local b = (hex%256)/255
    return r,g,b
end
function api.update_palette(updater,palette)
    for k,v in pairs(palette) do
        updater(k,table.unpack(v))
    end
end
function api.update(box)
    box:push_updates()
    box:draw()
end

local BUILDS = {}
local count_sort = function(a,b) return a.count > b.count end
function graphic.build_drawing_char(arr)
    local cols,fin,char,visited = {},{},{},{}
    local entries = 0
    local build_id = ""
    for k = 1, 6 do
        build_id = build_id .. ("%x"):format(graphic.logify[arr[k]])
        if cols[arr[k]] == nil then
            entries = entries + 1
            cols[arr[k]] = {count=1,c=arr[k]}
        else cols[arr[k]] = {count=cols[arr[k]].count+1,c=cols[arr[k]].c}
        end
    end
    if not BUILDS[build_id] then
        for k,v in pairs(cols) do
            if not visited[v.c] then
                visited[v.c] = true
                if entries == 1 then t_insert(fin,v) end
                t_insert(fin,v)
            end
        end
        t_sort(fin, count_sort)
        local swap = true
        for k=1,6 do
            if arr[k] == fin[1].c then char[k] = 1
            elseif arr[k] == fin[2].c then char[k] = 0
            else
                swap = not swap
                char[k] = swap and 1 or 0
            end
        end
        if char[6] == 1 then for i = 1, 5 do char[i] = 1-char[i] end end
        local n = 128
        for i = 0, 4 do n = n + char[i+1]*2^i end
        if char[6] == 1 then BUILDS[build_id] = {s_char(n), fin[2].c, fin[1].c}
        else BUILDS[build_id] = {s_char(n), fin[1].c, fin[2].c}
        end
    end
    return t_unpack(BUILDS[build_id])
end

return PIXELBOX