local OUR_NAME, profiler = ...


function profiler.isFirstAddonLoaded()
    -- Are any other addons loaded?
    for i=1,GetNumAddOns() do
        if IsAddOnLoaded(i) then
            local name = GetAddOnInfo(i)
            if not name=="!Profiler" then
                return false, name
            end
        end
    end
    return true
end


local known = {}
function profiler.newGlobals()
    -- traverse global namespace looking for unknown names
    local new = {}
    for key,value in pairs(_G) do
        if type(key)=="string" and not known[key] then
            known[key] = value
            if type(value)=="function" or type(value)=="table" then
                new[key] = value
            end
        end
    end
    return new
end


profiler.namespaces = {
    [0] = {name="Root", title="Root", cpu=0, mem=0, value=profiler.namespaces}
}
function profiler.registerNamespace(name, namespace, parent, seen)
    if not seen then
        -- break cycles
        seen = {
            --[_G] = true,
            [profiler.namespaces] = true, -- TODO: find out WHY necessary
        }
    end

    local this = {}

    for key,value in pairs(namespace) do
        if type(value)=="function" and type(key)=="string" then
            this[key] = value
            this[#this+1] = {name=key, title=key, fun=value, cpu=0, type="function"}
        end

        if type(value)=="table" and type(key)=="string" and not seen[value] then
            seen[value] = true
            local child = profiler.registerNamespace(key, value, this, seen)
            if child then
                this[key] = child
                this[#this+1] = {name=key, title=key, namespace=child, type="table", cpu=0}
            end
        end
    end

    if #this>0 then
        if not parent then
            parent = profiler.namespaces
            parent[#parent+1] = {name=name, title=name, namespace=this, type="addon", cpu=0, mem=0}
            parent[name] = this
        end
        this[-1] = parent
        this[0] = {name=name,title=name,namespace=this,type="table"}
        return this
    else
        return nil
    end
end

function profiler.registerBlizzard()
    -- TODO
end


function profiler.updateTimes(namespace)
    if namespace==profiler.namespaces then
        UpdateAddOnCPUUsage()
        UpdateAddOnMemoryUsage()
    end
    local totalCPU = 0
    local totalMem = 0
    if type(namespace)=="function" then
        return GetFunctionCPUUsage(namespace)
    end
    for i=1,#namespace do
        local x = namespace[i]
        if x.type=="addon" then
            x.cpu = GetAddOnCPUUsage(x.name)
            x.mem = GetAddOnMemoryUsage(x.name)
        elseif x.type=="function" then
            x.cpu = GetFunctionCPUUsage(x.fun)
        elseif x.type=="table" then
            x.cpu = profiler.updateTimes(x.namespace)
        end

        totalCPU = totalCPU + x.cpu
        totalMem = totalMem + (x.mem or 0)
    end
    table.sort(namespace, function(a,b)
        if a.cpu==b.cpu then
            return a.name<b.name
        else
            return a.cpu>b.cpu
        end
    end)
    return totalCPU, totalMem
end
