Profiler = {}


--
-- Auto mode
--

local Known = {}
local RefersTo = {}
local SeenFirst = {}   -- first seen during loading this addon

function Profiler:traverseTable(traverse, fromAddon, basePath, tableSeen)
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
                Profiler:traverseTable(tab, fromAddon, basePath..name..".", tableSeen)
            end
        end
        if type(key) == "table" then
            local tab = key
            if not tableSeen[tab] then
                tableSeen[tab] = true
                Profiler:traverseTable(tab, fromAddon, basePath..name..".", tableSeen)
            end
        end

    end
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
    Profiler:traverseTable(Profiler, "Profiler")
    Profiler:traverseTable(_G, "Blizzard")
    local nProfiler, nBlizzard = 0, 0
    for _ in pairs(SeenFirst["Profiler"]) do nProfiler = nProfiler + 1 end
    for _ in pairs(SeenFirst["Blizzard"]) do nBlizzard = nBlizzard + 1 end

    print("Profiler loaded, registering", nProfiler, "own functions and", nBlizzard, "Blizzard functions.")
end

function Profiler.events:ADDON_LOADED(addon)
    if addon=="!Profiler" then return Profiler:Init() end

    -- assume new functions found are from the loaded addon
    Profiler:traverseTable(_G, addon)
    local nNew = 0
    for _ in pairs(SeenFirst[addon]) do nNew = nNew + 1 end
    print("Profiler: found", nNew, "new functions after", addon, "loaded.")
end

function Profiler.events:PLAYER_LOGIN(...)
    print("Player login:", ...)
end

function Profiler.events:PLAYER_ENTER_WORLD(...)
    print("Player enter world:", ...)
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