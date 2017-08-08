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
Profiler.frame = CreateFrame("Frame", "Profiler", UIParent)

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
    --[[
    Profiler:traverseTable(Profiler, "Profiler")
    Profiler:traverseTable(_G, "Blizzard")
    local nProfiler, nBlizzard = 0, 0
    for _ in pairs(SeenFirst["Profiler"]) do nProfiler = nProfiler + 1 end
    for _ in pairs(SeenFirst["Blizzard"]) do nBlizzard = nBlizzard + 1 end

    print("Profiler loaded, registering", nProfiler, "own functions and", nBlizzard, "Blizzard functions.")
    --]]
end

function Profiler.events:ADDON_LOADED(addon)
    if addon=="!Profiler" then return Profiler:Init() end

    --[[
    -- assume new functions found are from the loaded addon
    Profiler:traverseTable(_G, addon)
    local nNew = 0
    for _ in pairs(SeenFirst[addon]) do nNew = nNew + 1 end
    print("Profiler: found", nNew, "new functions after", addon, "loaded.")
    --]]
end

function Profiler.events:PLAYER_LOGIN(...)  
    print("Player login:", ...)
end

function Profiler.events:PLAYER_ENTERING_WORLD(...)
    Profiler:CreateUI()
    print("Player enter world:", ...)
end



function Profiler:CreateUI()
    local settings = {
        color = {
            border = {0.0, 0.0, 0.0, 0.8}, -- TODO: make a proper border
            titlebar = {0.05, 0.05, 0.05, 1.0},
            header = {0.8, 0.8, 0.8, 0.9}, --header = {0.1, 0.2, 0.3, 0.8},   couldn't stand to look at this dark thing anymore
            main = {1.0, 1.0, 1.0, 0.9},   --main = {0.04, 0.06, 0.10, 0.8},  ditto
        },
        font = {
            title = "GameFontNormalSmall",
            subtitle = "GameFontDisableSmall",
            text = "QuestFontNormalSmall",
            value = "QuestFontNormalSmall",
        },
        size = {
            window = {400, 200},
            titlebar = 15,
            header = 20,
            footer = 20,
        }
    }

    local function setbg(frame, color)
        frame.texture = frame:CreateTexture(nil, "MEDIUM")
        frame.texture:SetAllPoints(true)
        frame.texture:SetColorTexture(unpack(color))
        return texture
    end

    local window = CreateFrame("Frame", nil, UIParent)
    window:SetSize(unpack(settings.size.window))
    window:SetPoint("CENTER", 0, 0)
    setbg(window, settings.color.border)
    window:SetMovable(true)

    local titlebar = CreateFrame("Frame", nil, window)
    do
        titlebar:SetHeight(settings.size.titlebar)
        titlebar:SetPoint("TOPLEFT", 1, -1)
        titlebar:SetPoint("TOPRIGHT", -1, -1)
        setbg(titlebar, settings.color.titlebar)

        local title = titlebar:CreateFontString(nil, "MEDIUM", settings.font.title)
        title:SetText("Profiler")
        title:SetPoint("BOTTOMLEFT", 2, 3)

        local subtitle = titlebar:CreateFontString(nil, "MEDIUM", settings.font.subtitle)
        subtitle:SetText("Test")
        subtitle:SetPoint("LEFT", title, "RIGHT", 2, 0)

        local function titlebarMouseDown(self, button)
            if button=="LeftButton" then
                window:StartMoving()
            end
        end
        local function titlebarMouseUp(self, button)
            if button=="LeftButton" then
                window:StopMovingOrSizing()
            end
        end
        titlebar:SetScript("OnMouseDown", titlebarMouseDown)
        titlebar:SetScript("OnMouseUp", titlebarMouseUp)
    end

    local header = CreateFrame("Frame", nil, window)
    do
        header:SetHeight(settings.size.header)
        header:SetPoint("TOPLEFT", titlebar, "BOTTOMLEFT")
        header:SetPoint("TOPRIGHT", titlebar, "BOTTOMRIGHT")
        setbg(header, settings.color.header)
    end
    local footer = CreateFrame("Frame", nil, window)
    do
        footer:SetHeight(settings.size.footer)
        footer:SetPoint("BOTTOMLEFT", 1, 1)
        footer:SetPoint("BOTTOMRIGHT", -1, 1)
        setbg(footer, settings.color.header)
    end

    local mainArea = CreateFrame("Frame", nil, window)
    do
        mainArea:SetPoint("TOPLEFT", header, "BOTTOMLEFT")
        mainArea:SetPoint("TOPRIGHT", header, "BOTTOMRIGHT")
        mainArea:SetPoint("BOTTOMLEFT", footer, "TOPLEFT")
        mainArea:SetPoint("BOTTOMRIGHT", footer, "TOPRIGHT")

        setbg(mainArea, settings.color.main)
    end

    local rows = {}
    do
        local rowHeight = 15
        local maxRows = math.floor(mainArea:GetHeight()/rowHeight)
        for i=1, maxRows do
            local offset = (i-1)*rowHeight
            local row = CreateFrame("StatusBar", nil, mainArea)
            row:SetHeight(rowHeight)
            row:SetPoint("TOPLEFT", mainArea, "TOPLEFT", 0, -offset)
            row:SetPoint("TOPRIGHT", mainArea, "TOPRIGHT", 0, -offset)
            
            local text = row:CreateFontString(nil, "MEDIUM", settings.font.text)
            text:SetPoint("LEFT", 2, 0)
            text:SetText("None")

            local valuetext = row:CreateFontString(nil, "MEDIUM", settings.font.value)
            valuetext:SetPoint("RIGHT", -2, 0)
            valuetext:SetText("0.0")
            rows[#rows+1] = row
        end
    end
    window:Show()
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
