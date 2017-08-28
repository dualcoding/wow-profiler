local OUR_NAME, profiler = ...


-- Add some Blizzard functions that we are probably exlusive users of to our namespace
profiler.Blizzard = profiler.Blizzard or {}
profiler.Blizzard["UpdateAddOnCPUUsage"] = UpdateAddOnCPUUsage
profiler.Blizzard["UpdateAddOnMemoryUsage"] = UpdateAddOnMemoryUsage
profiler.Blizzard["GetFunctionCPUUsage"] = GetFunctionCPUUsage

local cache = nil or function(f) return f end
local UpdateAddOnCPUUsage    = cache(_G.UpdateAddOnCPUUsage)
local UpdateAddOnMemoryUsage = cache(_G.UpdateAddOnMemoryUsage)
local GetFunctionCPUUsage    = cache(_G.GetFunctionCPUUsage)


function profiler.freezeStartup()
    -- update the cpu value first
    profiler.updateTimes(profiler.namespaces)
    for name,addon in pairs(profiler.namespaces) do
        profiler.updateTimes(addon)
    end

    local ns = profiler.namespaces
    local stack = {}
    repeat
        for i=1,#ns do
            local x = ns[i]
            x.startup = x.cpu
            stack[#stack+1] = x.namespace
        end
        ns = table.remove(stack)
    until not ns
end


function profiler.updateTimes(namespace, sortby, includeSubroutines)
    if namespace==profiler.namespaces then
        UpdateAddOnCPUUsage()
        UpdateAddOnMemoryUsage()
    end
    local totalCPU = 0
    local totalMem = 0
    if type(namespace)=="function" then
        return GetFunctionCPUUsage(namespace, includeSubroutines)
    end
    for i=1,#namespace do
        local x = namespace[i]
        if x.type=="addon" then
            x.cpu = GetAddOnCPUUsage(x.name)
            local mem = GetAddOnMemoryUsage(x.name)
            x.memlast = x.mem
            x.mem = mem
            x.memdiff = mem - x.memlast
        elseif x.type=="function" then
            x.cpu, x.ncalls = GetFunctionCPUUsage(x.fun, includeSubroutines)
        elseif x.type=="table" then
            x.cpu = profiler.updateTimes(x.namespace, sortby, includeSubroutines)
        end
        x.updatecpu = x.cpu - (x.startup or 0)

        totalCPU = totalCPU + x.cpu
        totalMem = totalMem + (x.mem or 0)
    end

    sortby = sortby or "startup"

    local function sort(t, fun)
        -- Sorting tables first ended up being too much scrolling
        --return table.sort(t, function(a,b)
        --    if     a.type=="table" and b.type~="table" then return true
        --    elseif a.type~="table" and b.type=="table" then return false
        --    end
        --    return fun(a,b)
        --end)
        return table.sort(t, fun)
    end

    if sortby=="cpu" then
        sort(namespace, function(a,b)
            if a.cpu==b.cpu then
                return a.name<b.name
            else
                return a.cpu>b.cpu
            end
        end)
    elseif sortby=="name" then
        sort(namespace, function(a,b)
            return a.name<b.name
        end)
    --elseif sortby=="mem" then
    elseif sortby=="ncalls" then
        sort(namespace, function(a,b)
            acalls = a.ncalls or a.memdiff or 0
            bcalls = b.ncalls or b.memdiff or 0
            if acalls==bcalls then
                return a.name<b.name
            else
                return acalls>bcalls
            end
        end)
    elseif sortby=="startup" then
        sort(namespace, function(a,b)
            a.startup = a.startup or 0
            b.startup = b.startup or 0
            if a.startup==b.startup then
                if a.name and b.name then
                    return a.name<b.name
                end
            else
                return a.startup>b.startup
            end
        end)
    elseif sortby=="updatecpu" then
        sort(namespace, function(a,b)
            if a.updatecpu == b.updatecpu then
                return a.name<b.name
            end
            return a.updatecpu>b.updatecpu
        end)
    end
    return totalCPU, totalMem
end
