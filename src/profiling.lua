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


local newGlobals
function profiler.newGlobals()
    local res
    if newGlobals then res = newGlobals end
    newGlobals = {}
    local mt = {
        __newindex = function(t, k, v)
            newGlobals[k] = v
            rawset(t,k,v)
        end,
    }
    setmetatable(_G, mt)

    return res
end


profiler.namespaces = {
    [0] = {name="Root", title="Root", cpu=0, mem=0, value=profiler.namespaces}
}
function profiler.registerNamespace(name, namespace, parent, seen)
    -- TODO: only add tables with functions
    local has_function_child
    if not seen then
        -- break cycles
        seen = {
            --[_G] = true,
            [profiler.namespaces] = true, -- TODO: find out WHY necessary
        }
    end

    local this = {}
    if not parent then
        parent = profiler.namespaces
        parent[#parent+1] = {name=name, title=name, namespace=this, type="addon", cpu=0, mem=0}
    else
        parent[#parent+1] = {name=name, title=name, namespace=this, type="table", cpu=0}
    end
    parent[name] = this
    this[-1] = parent
    this[0] = parent[#parent]
    for key,value in pairs(namespace) do
        if type(value)=="function" and type(key)=="string" then
            this[key] = value
            this[#this+1] = {name=key, title=key, fun=value, cpu=0, type="function"}
            has_function_child = true
        end

        if type(value)=="table" and type(key)=="string" and not seen[value] then
            seen[value] = true
            profiler.registerNamespace(key, value, this, seen)
        end
    end
    return has_function_child
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
    table.sort(namespace, function(a,b) return a.cpu>b.cpu end)
    return totalCPU, totalMem
end
