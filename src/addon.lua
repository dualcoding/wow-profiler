local ADDON_NAME, profiler = ...

--
-- Auto mode
--

local Known = {}
local RefersTo = {}
SeenFirst = {}   -- first seen during loading this addon

function profiler.traverseTable(traverse, fromAddon, basePath, tableSeen)
    -- Traverse the given table to find functions, attributing them to the given addon name

    local basePath = basePath or ""
    local tableSeen = tableSeen or {} -- used to avoid cycles

    for key,value in pairs(traverse) do
        local name = tostring(key)

        -- add any found functions
        if type(value) == "function" then
            local func = value
            RefersTo[basePath..name] = func
            if not Known[func] then
                Known[func] = true
                if not SeenFirst[fromAddon] then SeenFirst[fromAddon] = {} end
                SeenFirst[fromAddon][func] = basePath..name
            end
        end
        if type(key) == "function" then
            local func = key
            RefersTo[basePath..name] = func
            if not Known[func] then
                Known[func] = true
                if not SeenFirst[fromAddon] then SeenFirst[fromAddon] = {} end
                SeenFirst[fromAddon][func] = basePath..name
            end

        end

        -- recurse subtables
        if type(value) == "table" then
            local tab = value
            if not tableSeen[tab] then
                tableSeen[tab] = true
                profiler.traverseTable(tab, fromAddon, basePath..name..".", tableSeen)
            end
        end
        if type(key) == "table" then
            local tab = key
            if not tableSeen[tab] then
                tableSeen[tab] = true
                profiler.traverseTable(tab, fromAddon, basePath..name..".", tableSeen)
            end
        end

    end
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



--
-- Load addon
--

profiler.events = {}
profiler.frame = CreateFrame("Frame", "Profiler", UIParent)

function profiler.init()
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
    profiler.traverseTable(profiler, "!Profiler")
    profiler.traverseTable(_G, "Blizzard")
    local nProfiler, nBlizzard = 0, 0
    for _ in pairs(SeenFirst["!Profiler"]) do nProfiler = nProfiler + 1 end
    for _ in pairs(SeenFirst["Blizzard"]) do nBlizzard = nBlizzard + 1 end

    print("Profiler loaded, registering", nProfiler, "own functions and", nBlizzard, "Blizzard functions.")
end

function profiler.events:ADDON_LOADED(addon)
    if addon==ADDON_NAME then return profiler.init() end

    --profiler.auto.addonLoaded(addon)
    -- assume new functions found are from the loaded addon
    profiler.traverseTable(_G, addon)
    local nNew = 0
    for _ in pairs(SeenFirst[addon]) do nNew = nNew + 1 end
    print("Profiler: found", nNew, "new functions after", addon, "loaded.")
    --]]
end

function profiler.events:PLAYER_LOGIN(...)
    print("Player login:", ...)
end

function profiler.events:PLAYER_ENTERING_WORLD(...)
    profiler.ui.Window:init()
    print("Player enter world:", ...)
end



function profiler.enable()
    local events = profiler.events
    local frame = profiler.frame
    frame:SetScript("OnEvent", function(self, event, ...)
        events[event](self, ...)
    end)
    for k, v in pairs(events) do
        frame:RegisterEvent(k)
    end
end

profiler.enable()
