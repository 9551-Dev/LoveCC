local function make_methods(child)
    return setmetatable({
        __build=function(obj)
            child = obj 
            return obj
        end,
        release = function()
            child.stored_in[child.under] = nil
        end,
        type = function() return child.obj_type end,
        typeOf = function(this,tp) return tp == child.obj_type end
    },{__tostring=function() return "object" end})
end

return {new=function(child)
    return setmetatable(child,{__index=make_methods(child)})
end}