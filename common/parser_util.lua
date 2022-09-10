local parse = {}

function parse.stack_trace(trace)
    local res = ""
    for c in trace:gmatch("(%[C%]:.-)\n") do
        res = res .. c .. "\n"
    end
    return res
end

return parse