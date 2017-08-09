Profiler = {}
function Profiler:test()
    print("test success!")
end

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
    local colors = {
        --               R       G      B      A
        windowborder = {0.00,  0.00,  0.00,  1.00},
        titlebar     = {0.05,  0.05,  0.05,  1.00},
        header       = {0.80,  0.80,  0.80,  0.90},
        workspace    = {1.00,  1.00,  1.00,  0.90},
    }
    local fonts = {
        title    = "GameFontNormalSmall",
        subtitle = "GameFontDisableSmall",
        text     = "QuestFontNormalSmall",
        value    = "QuestFontNormalSmall",
    }

    local function edgecolor(frame, color)
        -- ...yeah. Switch to file edge textures at some point.
        local left = frame:CreateTexture(nil)
        left:SetPoint("topleft", -1, 1)
        left:SetPoint("bottomleft", -1, -1)
        left:SetWidth(1)
        left:SetColorTexture(unpack(color))
        
        local top = frame:CreateTexture(nil)
        top:SetPoint("topleft", -1, 1)
        top:SetPoint("topright", 1, 1)
        top:SetHeight(1)
        top:SetColorTexture(unpack(color))

        local right = frame:CreateTexture(nil)
        right:SetPoint("topright", 1, 1)
        right:SetPoint("bottomright", 1, -1)
        right:SetWidth(1)
        right:SetColorTexture(unpack(color))

        local bottom = frame:CreateTexture(nil)
        bottom:SetPoint("bottomleft",  -1, -1)
        bottom:SetPoint("bottomright",  1, -1)
        bottom:SetHeight(1)
        bottom:SetColorTexture(unpack(color))
    end
    local function bgcolor(frame, bg, edge)
        local texture = frame:CreateTexture(nil, "MEDIUM")
        texture:SetAllPoints(true)
        texture:SetColorTexture(unpack(bg))
        if edge then edgecolor(frame, edge) end
        return texture
    end
    
    local function align(frame, point, anchor, relativeTo, offsets)
        local inset, gap, x, y = 0, 0, 0, 0
        if offsets then
            inset = offsets.inset or 0
            gap = offsets.gap or 0
            x = offsets.x or 0
            y = offsets.y or 0
        end
        if point=="below" then
            local rel = relativeTo or "bottom"
            frame:SetPoint("topleft",  anchor, rel.."left",   inset, -gap)
            frame:SetPoint("topright", anchor, rel.."right", -inset, -gap)
        elseif point=="above" then
            local rel = relativeTo or "top"
            frame:SetPoint("bottomleft",  anchor, rel.."left",   inset, gap)
            frame:SetPoint("bottomright", anchor, rel.."right", -inset, gap)
        else
            local rel = relativeTo or point
            if anchor then
                frame:SetPoint(point, anchor, rel, x, y)
            else
                frame:SetPoint(point, x, y)
            end
        end
    end

    local function size(frame, width, height)
        if width then frame:SetWidth(width) end
        if height then frame:SetHeight(height) end
        return frame
    end
    local function height(frame, height)
        frame:SetHeight(height)
        return frame
    end
    local function width(frame, width)
        frame:SetWidth(width)
        return frame
    end

    local function box(parent, bg, name)
        local frame = CreateFrame("Frame", name, parent)
        if bg then bgcolor(frame, bg) end
        return frame
    end
    local function text(parent, text, font)
        local fontstring = parent:CreateFontString(nil, "MEDIUM", font)
        fontstring:SetText(text)
        return fontstring
    end


    local window = CreateFrame("Frame", "ProfilerWindow", UIParent)
    size(window, 400, 200); align(window, "center"); bgcolor(window, colors.windowborder, {1.0, 0.0, 0.0, 1.0})
    window:SetMovable(true)

    local titlebar = box(window, colors.titlebar)
    do
        height(titlebar, 20)
        align(titlebar, "below", window, "top", {inset=1, gap=1})

        local title = text(titlebar, "Profiler", fonts.title)
        align(title, "left", titlebar)

        local subtitle = text(titlebar, "Test", fonts.subtitle)
        align(subtitle, "left", title, "right", {gap=2})

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

    local header = box(window, colors.header)
    align(header, "below", titlebar); height(header, 20)

    local footer = box(window, colors.header)
    height(footer, 20)
    align(footer, "above", window, "bottom", {inset=1, gap=1})

    local workspace = CreateFrame("Frame", nil, window)
    do
        workspace:SetPoint("TOPLEFT", header, "BOTTOMLEFT")
        workspace:SetPoint("BOTTOMRIGHT", footer, "TOPRIGHT")

        bgcolor(workspace, colors.workspace)
    end

    local rows = {}
    do
        local rowHeight = 15
        local maxRows = math.floor(workspace:GetHeight()/rowHeight)
        for i=1, maxRows do
            local offset = (i-1)*rowHeight
            local row = CreateFrame("StatusBar", nil, workspace)
            row:SetHeight(rowHeight)
            row:SetPoint("TOPLEFT", workspace, "TOPLEFT", 0, -offset)
            row:SetPoint("TOPRIGHT", workspace, "TOPRIGHT", 0, -offset)
            
            local text = row:CreateFontString(nil, "MEDIUM", fonts.text)
            text:SetPoint("LEFT", 2, 0)
            text:SetText("None")

            local valuetext = row:CreateFontString(nil, "MEDIUM", fonts.value)
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
