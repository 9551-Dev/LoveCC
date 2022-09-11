return function(ENV)
    ENV.love.handlers = setmetatable({},
        {__index=function()
            return function()
        end
    end})
end