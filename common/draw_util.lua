local draw = {}

function draw.respect_newlines(term,text)
    local sx,sy = term.getCursorPos()
    local lines = 0
    for c in text:gmatch("([^\n]+)") do
        lines = lines + 1
        term.setCursorPos(sx,sy)
        term.write(c)
        sy = sy + 1
    end
    return lines
end

return draw