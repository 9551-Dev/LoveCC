return {ev="char",run=function(BUS,caller,ev,char)
    BUS.events[#BUS.events+1] = {"textinput",char}

    if type(caller.textinput) == "function" then
        caller.textinput(char)
    end
end}