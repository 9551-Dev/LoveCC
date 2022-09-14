local object = require("core.object")

local font_object = {
    __index = object.new{
        getAscent   = function(this) return this.meta.ascent end,
        getDescent  = function(this) return this.meta.descent end,
        getBaseline = function(this) return this.meta.baseline or 0 end,
        getDPIScale = function(this) return this.meta.DPI_scale or 1 end,
        getFilter   = function(this)
            return this.meta.filter.min,
                this.meta.filter.mag,
                this.meta.filter.anisotropy
        end,
        getHeight     = function(this) return this.size.height end,
        getKerning    = function() return 1 end,
        getLineHeight = function(this) return this.line_height end,
        getWidth      = function(this,text)
            local width = 0
            for c in text:gmatch(".") do
                width = width + this[c].bounds.width + 1
            end
            return width
        end,
        getWrap      = function() error("Font:getWrap is not implemented yet") end,
        hasGlyphs    = function() return false end,
        setFallbacks = function() error("Font:setFallbacks is not implemented yet") end,
        setFilter    = function(this,min,mag,anisotropy)
            this.meta.filter.min = min or "nearest"
            this.meta.filter.mag = mag or "nearest"
            this.meta.filter.anisotropy = anisotropy or 0
        end,
        setLineHeight = function(this,height)
            this.line_height = height or 1
        end
    },
    __tostring = function() return "Font" end
}

return {add=function(BUS)
    return {new=function(path,internal)
        local extension = path:match("^.+(%..+)$")

        local font_path = fs.combine(BUS.instance.libdir,path)
        if not internal then
            font_path = fs.combine(BUS.instance.gamedir,path)
        end

        local parser = require("core.loaders.font" .. extension)

        local font_data = parser.read(font_path)

        return setmetatable(font_data,font_object):__build()
    end}
end}