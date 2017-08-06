-- Utility & Misc
function p(t, depth)
    local depth = depth or 0
    for k,v in pairs(t) do
        print(string.rep(" ", depth*4), k,v)
        if type(v)=="table" then p(v, depth+1) end
    end
end



Profiler = {}

--
-- Find functions
--

Known = {}
Keys = {}
Profiler.byAddOn = {}

local byAddOn = Profiler.byAddOn

local newcount = 0
function Profiler:traverseTable(t, addon, seen)
    if not byAddOn[addon] then byAddOn[addon] = {} end
    if not seen then newcount = 0 end
    local seen = seen or {} -- avoid cycles
    for k,v in pairs(t) do
        local name = type(k)=="string" and k or tostring(k)
        if type(v) == "function" then
            if not Known[v] then
                if name~=Known[v] then print("replaced", name) end
                newcount = newcount + 1
                Known[v] = name
                From[v] = addon
                byAddOn[addon][name] = v
            end
        end
        if type(k) == "function" then
            if not Known[k] then
                newcount = newcount + 1
                Known[k] = name
                From[k] = addon
                byAddOn[addon][name] = k
            end 
        end
        if type(v) == "table" then
            if not seen[v] then
                seen[v] = true
                Profiler:traverseTable(v, addon, seen)
            end
        end
        if type(k) == "table" then
            if not seen[k] then
                seen[k] = true
                Profiler:traverseTable(k, addon, seen)
            end
        end
    end
    return newcount
end

function Profiler:RecordCurrentTimes(name)
    -- TODO
    -- save times
    -- reset profiling
end




--
-- Load addon
--
Profiler.events = {}
Profiler.frame = CreateFrame("Frame")

function Profiler:Init()
    -- Warn if any other addons were loaded before us
    for i=1,GetNumAddOns() do
        if IsAddOnLoaded(i) then
            local name = GetAddOnInfo(i)
            if not name=="!Profiler" then
                print("AddOn loaded before Profiler:", name..". Functions will be misattributed to Blizzard.")
            end
        end
    end

    -- Claim our own functions, then attribute all other globals to Blizzard
    local profiler = Profiler:traverseTable(Profiler, "Profiler")
    local blizzard = Profiler:traverseTable(_G, "Blizzard")
    print("Profiler loaded, registering", profiler, "own functions and", blizzard, "Blizzard functions.")
end

function Profiler.events:ADDON_LOADED(addon)
    if addon=="!Profiler" then return Profiler:Init() end

    -- assume new functions are from addon
    local new = Profiler:traverseTable(_G, addon)
    print("Profiler: found", new, "new functions after", addon, "loaded.")
end

function Profiler.events:PLAYER_LOGIN(...)
    print("Player login:", ...)
end

function Profiler.events:PLAYER_ENTER_WORLD(...)
    print("Player enter world:", ...)
    Profiler:RecordCurrentTimes("Startup") -- TODO: only first time
end


function Profiler:Enable()
    local events = Profiler.events
    local frame = Profiler.frame
    frame:SetScript("OnEvent", function(self, event, ...)
        events[event](self, ...)
    end)
    for k, v in pairs(events) do
        frame:RegisterEvent(k)
    end
end

Profiler:Enable()



function t()
    UpdateAddOnCPUUsage()
    for addon,fs in pairs(byAddOn) do
        local total = 0
        for name,f in pairs(fs) do
            local time = GetFunctionCPUUsage(f)
            total = total + time
        end
        print(string.format("%-70.70s %6.2f %6.2f", addon, GetAddOnCPUUsage(addon), total))
    end
end