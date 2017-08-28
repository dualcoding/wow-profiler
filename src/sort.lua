local sortby = function(par)
    return function(a,b)
        if     a.type=="table" and b.type~="table" then return true
        elseif a.type~="table" and b.type=="table" then return false
        end
        if a[par] == b[par] then return a.name<b.name end
        return a[par]>a[par]
    end
end
