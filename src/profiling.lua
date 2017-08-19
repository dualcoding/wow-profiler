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


profiler.namespaces = {}
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

    local parent = parent or profiler.namespaces
    local this = {}
    parent[name] = this
    this[-1] = parent
    for key,value in pairs(namespace) do
        if type(value)=="function" and type(key)=="string" then
            this[key] = value
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


function profiler.updateAddOnInfo()
    UpdateAddOnCPUUsage()
    UpdateAddOnMemoryUsage()
    local res = {}
    for i=1,GetNumAddOns() do
        local name,title,notes,loadable,reason,security = GetAddOnInfo(i)
        res[i] = {name=name, title=title ,cpu=GetAddOnCPUUsage(i), mem=GetAddOnMemoryUsage(i)}
    end
    return res
end
